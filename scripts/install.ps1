# Install shopify-theme-image-performance skill for Cursor, Codex, Claude Code, or a project repo.
#Requires -Version 5.1
param(
  [switch]$Cursor,
  [switch]$Codex,
  [switch]$Claude,
  [string]$Project = "",
  [switch]$All,
  [switch]$Force,
  [switch]$Link,
  [switch]$Help
)

$ErrorActionPreference = "Stop"

$SkillName = "shopify-theme-image-performance"
$SrcDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$SkillFiles = @("SKILL.md", "examples.md")
$OptionalDirs = @("agents")

function Show-Usage {
  @"
用法: .\scripts\install.ps1 [选项]

将本仓库中的 Skill 安装到 AI 工具的配置目录（Windows PowerShell）。

选项:
  -Cursor          安装到 %USERPROFILE%\.cursor\skills\<skill-name>\
  -Codex           安装到 %USERPROFILE%\.codex\skills\<skill-name>\
  -Claude          安装到 %USERPROFILE%\.claude\skills\<skill-name>\
  -Project <DIR>   安装到 <DIR>\.cursor\skills\<skill-name>\（省略路径则用当前目录）
  -All             安装到 Cursor + Codex（无参数时等同 -All）
  -Force           覆盖已存在的安装目录
  -Link            创建目录符号链接（需开发者模式或管理员；失败时请去掉 -Link）
  -Help            显示帮助

示例:
  .\scripts\install.ps1 -All
  .\scripts\install.ps1 -Cursor -Force
  .\scripts\install.ps1 -Project C:\path\to\my-shopify-theme

远程一键安装:
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile `$env:TEMP\install-skill.ps1; & `$env:TEMP\install-skill.ps1 -All }"

macOS / Linux / Git Bash 请使用: ./scripts/install.sh
"@
}

function Fail([string]$Message) {
  Write-Error $Message
  exit 1
}

function Test-SkillSource {
  $skillMd = Join-Path $SrcDir "SKILL.md"
  if (-not (Test-Path -LiteralPath $skillMd -PathType Leaf)) {
    Fail "未找到 $skillMd，请在仓库根目录运行此脚本。"
  }
}

function Install-One([string]$DestRoot) {
  $dest = Join-Path $DestRoot $SkillName

  if (Test-Path -LiteralPath $dest) {
    if ($Force) {
      Remove-Item -LiteralPath $dest -Recurse -Force
    }
    else {
      Fail "目标已存在: $dest（使用 -Force 覆盖）"
    }
  }

  if (-not (Test-Path -LiteralPath $DestRoot)) {
    New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null
  }

  if ($Link) {
    try {
      New-Item -ItemType SymbolicLink -Path $dest -Target $SrcDir -Force | Out-Null
      Write-Host "已链接 -> $dest"
      return
    }
    catch {
      Fail "创建符号链接失败: $($_.Exception.Message)。请去掉 -Link 改用复制安装，或开启 Windows 开发者模式后以管理员运行。"
    }
  }

  New-Item -ItemType Directory -Path $dest -Force | Out-Null

  foreach ($file in $SkillFiles) {
    $src = Join-Path $SrcDir $file
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
      Fail "缺少源文件: $src"
    }
    Copy-Item -LiteralPath $src -Destination (Join-Path $dest $file) -Force
  }

  foreach ($dir in $OptionalDirs) {
    $srcDirPath = Join-Path $SrcDir $dir
    if (Test-Path -LiteralPath $srcDirPath -PathType Container) {
      Copy-Item -LiteralPath $srcDirPath -Destination (Join-Path $dest $dir) -Recurse -Force
    }
  }

  Write-Host "已安装 -> $dest"
}

function Get-UserHome {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  return $env:HOME
}

if ($Help) {
  Show-Usage
  exit 0
}

$installCursor = $Cursor.IsPresent
$installCodex = $Codex.IsPresent
$installClaude = $Claude.IsPresent
$installProject = $PSBoundParameters.ContainsKey("Project")

if ($All) {
  $installCursor = $true
  $installCodex = $true
}

if (-not ($installCursor -or $installCodex -or $installClaude -or $installProject)) {
  $installCursor = $true
  $installCodex = $true
}

Test-SkillSource

$homeDir = Get-UserHome
if (-not $homeDir) {
  Fail "无法解析用户主目录（USERPROFILE / HOME 未设置）。"
}

if ($installCursor) {
  Install-One (Join-Path $homeDir ".cursor\skills")
}
if ($installCodex) {
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeDir ".codex" }
  Install-One (Join-Path $codexHome "skills")
}
if ($installClaude) {
  Install-One (Join-Path $homeDir ".claude\skills")
}
if ($installProject) {
  $root = if ($Project) { $Project } else { (Get-Location).Path }
  $root = (Resolve-Path -LiteralPath $root).Path
  Install-One (Join-Path $root ".cursor\skills")
}

Write-Host ""
Write-Host "完成。在 Cursor / Codex 中打开 Shopify 主题项目后，可对 Agent 说："
Write-Host "  「按 shopify-theme-image-performance 分析这个 section 的图片加载」"
if ($installCodex) {
  Write-Host "Codex 用户：安装后请重启 Codex 以加载新 Skill。"
}
