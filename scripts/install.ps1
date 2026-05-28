# Install shopify-theme-image-performance skill for Cursor, Codex, or Claude Code.
#Requires -Version 5.1
param(
  [switch]$Cursor,
  [switch]$Codex,
  [switch]$Claude,
  [switch]$All,
  [switch]$Force,
  [switch]$Link,
  [switch]$Help
)

$ErrorActionPreference = "Stop"

$SkillName = "shopify-theme-image-performance"
$GithubRepo = if ($env:SKILL_INSTALL_REPO) { $env:SKILL_INSTALL_REPO } else { "yalin28/shopify-theme-image-performance-skill" }
$GithubRef = if ($env:SKILL_INSTALL_REF) { $env:SKILL_INSTALL_REF } else { "main" }

$Script:SrcDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$DownloadTmp = $null

$SkillFiles = @("SKILL.md", "examples.md")
$OptionalDirs = @("agents")

function Show-Usage {
  @"
用法: .\scripts\install.ps1 [选项]

将本仓库中的 Skill 安装到 AI 工具的配置目录（Windows PowerShell）。

选项:
  -Cursor          安装到 %USERPROFILE%\.cursor\skills\<skill-name>\
  -Codex           安装到 %USERPROFILE%\.agents\skills\<skill-name>\，并兼容 %USERPROFILE%\.codex\skills\<skill-name>\
  -Claude          安装到 %USERPROFILE%\.claude\skills\<skill-name>\
  -All             安装到 Cursor + Codex + Claude Code
  -Force           覆盖已存在的安装目录
  -Link            创建目录符号链接（需开发者模式或管理员；失败时请去掉 -Link）
  -Help            显示帮助

示例:
  .\scripts\install.ps1 -Cursor -Force
  .\scripts\install.ps1 -Codex
  .\scripts\install.ps1 -Claude

远程安装（从 GitHub 拉取 Skill 文件后安装，按平台选择）:
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile `$env:TEMP\install-skill.ps1; & `$env:TEMP\install-skill.ps1 -Cursor }"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile `$env:TEMP\install-skill.ps1; & `$env:TEMP\install-skill.ps1 -Codex }"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile `$env:TEMP\install-skill.ps1; & `$env:TEMP\install-skill.ps1 -Claude }"

macOS / Linux / Git Bash 请使用: ./scripts/install.sh
"@
}

function Fail([string]$Message) {
  Write-Error $Message
  exit 1
}

function Ensure-Source {
  if (Test-Path -LiteralPath (Join-Path $Script:SrcDir "SKILL.md") -PathType Leaf) {
    return
  }

  Write-Host "未检测到本地仓库，正在从 GitHub 获取 Skill 文件（${GithubRepo}@${GithubRef}）..."
  $base = "https://raw.githubusercontent.com/$GithubRepo/$GithubRef"
  $tmp = Join-Path $env:TEMP "skill-install-$([Guid]::NewGuid().ToString('N'))"
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  $Script:DownloadTmp = $tmp

  try {
    Invoke-WebRequest -Uri "$base/SKILL.md" -OutFile (Join-Path $tmp "SKILL.md") -UseBasicParsing
    Invoke-WebRequest -Uri "$base/examples.md" -OutFile (Join-Path $tmp "examples.md") -UseBasicParsing
    New-Item -ItemType Directory -Path (Join-Path $tmp "agents") -Force | Out-Null
    try {
      Invoke-WebRequest -Uri "$base/agents/openai.yaml" -OutFile (Join-Path $tmp "agents\openai.yaml") -UseBasicParsing
    }
    catch {
      # agents 为可选
    }
  }
  catch {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Fail "从 GitHub 下载失败: $($_.Exception.Message)"
  }

  $Script:SrcDir = $tmp
}

function Test-SkillSource {
  if (-not (Test-Path -LiteralPath (Join-Path $Script:SrcDir "SKILL.md") -PathType Leaf)) {
    Fail "未找到 SKILL.md。"
  }
  if (-not (Test-Path -LiteralPath (Join-Path $Script:SrcDir "examples.md") -PathType Leaf)) {
    Fail "未找到 examples.md。"
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
    if ($DownloadTmp) {
      Fail "远程下载模式不支持 -Link，请先 git clone 仓库后再链接安装"
    }
    try {
      New-Item -ItemType SymbolicLink -Path $dest -Target $Script:SrcDir -Force | Out-Null
      Write-Host "已链接 -> $dest"
      return
    }
    catch {
      Fail "创建符号链接失败: $($_.Exception.Message)。请去掉 -Link 改用复制安装，或开启 Windows 开发者模式后以管理员运行。"
    }
  }

  New-Item -ItemType Directory -Path $dest -Force | Out-Null

  foreach ($file in $SkillFiles) {
    $src = Join-Path $Script:SrcDir $file
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
      Fail "缺少源文件: $src"
    }
    Copy-Item -LiteralPath $src -Destination (Join-Path $dest $file) -Force
  }

  foreach ($dir in $OptionalDirs) {
    $srcDirPath = Join-Path $Script:SrcDir $dir
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

function Install-Codex([string]$HomeDir) {
  $standardRoot = if ($env:CODEX_AGENT_SKILLS_DIR) { $env:CODEX_AGENT_SKILLS_DIR } else { Join-Path $HomeDir ".agents\skills" }
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HomeDir ".codex" }
  $legacyRoot = Join-Path $codexHome "skills"

  Install-One $standardRoot
  if ($legacyRoot -ne $standardRoot) {
    Install-One $legacyRoot
  }
}

if ($Help) {
  Show-Usage
  exit 0
}

$installCursor = $Cursor.IsPresent
$installCodex = $Codex.IsPresent
$installClaude = $Claude.IsPresent

if ($All) {
  $installCursor = $true
  $installCodex = $true
  $installClaude = $true
}

if (-not ($installCursor -or $installCodex -or $installClaude)) {
  Show-Usage
  Fail "请明确选择安装目标：-Cursor、-Codex、-Claude 或 -All"
}

try {
  Ensure-Source
  Test-SkillSource

  $homeDir = Get-UserHome
  if (-not $homeDir) {
    Fail "无法解析用户主目录（USERPROFILE / HOME 未设置）。"
  }

  if ($installCursor) {
    Install-One (Join-Path $homeDir ".cursor\skills")
  }
  if ($installCodex) {
    Install-Codex $homeDir
  }
  if ($installClaude) {
    Install-One (Join-Path $homeDir ".claude\skills")
  }
  Write-Host ""
  Write-Host "完成。验证: .\scripts\verify-install.ps1"
  Write-Host "使用: 在 Shopify 主题项目中对 Agent 说「按 shopify-theme-image-performance 分析这个 section 的图片加载」"
  if ($installCodex) {
    Write-Host "Codex: 安装后请重启以加载新 Skill。"
  }
}
finally {
  if ($DownloadTmp -and (Test-Path -LiteralPath $DownloadTmp)) {
    Remove-Item -LiteralPath $DownloadTmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
