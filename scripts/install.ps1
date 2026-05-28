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
$SkillDisplay = "Shopify Theme Image Performance"
$GithubRepo = if ($env:SKILL_INSTALL_REPO) { $env:SKILL_INSTALL_REPO } else { "yalin28/shopify-theme-image-performance-skill" }
$GithubRef = if ($env:SKILL_INSTALL_REF) { $env:SKILL_INSTALL_REF } else { "main" }

$Script:SrcDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$DownloadTmp = $null
$Script:InstalledCount = 0
$Script:SkippedCount = 0

$SkillFiles = @("SKILL.md")
$OptionalDirs = @("agents")

function Write-Info([string]$Message)  { Write-Host "  $(([char]0x1F4AC)) $Message" }
function Write-Step([string]$Message)  { Write-Host "  $([char]0x25B8) $Message" }
function Write-Ok([string]$Message)    { Write-Host "  $([char]0x2705) $Message" }
function Write-Warn([string]$Message)  { Write-Host "  $([char]0x26A0)$([char]0xFE0F)  $Message" }
function Write-Hint([string]$Message)  { Write-Host "  $([char]0x1F4A1) $Message" }

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
  Write-Host ""
  Write-Host "  $([char]0x274C) $Message" -ForegroundColor Red
  exit 1
}

function Ensure-Source {
  if (Test-Path -LiteralPath (Join-Path $Script:SrcDir "SKILL.md") -PathType Leaf) {
    return
  }

  Write-Step "未检测到本地仓库，正在从 GitHub 获取 Skill 文件..."
  Write-Info "来源: ${GithubRepo}@${GithubRef}"
  $base = "https://raw.githubusercontent.com/$GithubRepo/$GithubRef"
  $tmp = Join-Path $env:TEMP "skill-install-$([Guid]::NewGuid().ToString('N'))"
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  $Script:DownloadTmp = $tmp

  try {
    Invoke-WebRequest -Uri "$base/SKILL.md" -OutFile (Join-Path $tmp "SKILL.md") -UseBasicParsing
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
    Fail "下载 Skill 文件失败，请检查网络连接或仓库地址是否正确"
  }

  $Script:SrcDir = $tmp
}

function Test-SkillSource {
  if (-not (Test-Path -LiteralPath (Join-Path $Script:SrcDir "SKILL.md") -PathType Leaf)) {
    Fail "未找到 SKILL.md，无法继续安装。"
  }
}

function Install-One([string]$DestRoot, [string]$Label = "") {
  $dest = Join-Path $DestRoot $SkillName

  if ($Label) {
    Write-Step "正在安装到 ${Label}..."
  }

  if (Test-Path -LiteralPath $dest) {
    if ($Force) {
      Remove-Item -LiteralPath $dest -Recurse -Force
    }
    else {
      Write-Warn "该路径已存在: $dest"
      Write-Hint "Skill 之前已安装过，如需覆盖更新请添加 -Force 参数重新运行"
      $Script:SkippedCount++
      return
    }
  }

  if (-not (Test-Path -LiteralPath $DestRoot)) {
    New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null
  }

  if ($Link) {
    if ($DownloadTmp) {
      Fail "远程下载模式不支持 -Link，请先 git clone 仓库后再使用链接安装"
    }
    try {
      New-Item -ItemType SymbolicLink -Path $dest -Target $Script:SrcDir -Force | Out-Null
      Write-Ok "已通过符号链接安装 -> $dest"
      $Script:InstalledCount++
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

  Write-Ok "安装完成 -> $dest"
  $Script:InstalledCount++
}

function Get-UserHome {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  return $env:HOME
}

function Install-Codex([string]$HomeDir) {
  $standardRoot = if ($env:CODEX_AGENT_SKILLS_DIR) { $env:CODEX_AGENT_SKILLS_DIR } else { Join-Path $HomeDir ".agents\skills" }
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HomeDir ".codex" }
  $legacyRoot = Join-Path $codexHome "skills"

  Install-One $standardRoot "Codex (标准路径)"
  if ($legacyRoot -ne $standardRoot) {
    Install-One $legacyRoot "Codex (兼容路径)"
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
  Fail "请选择安装目标：-Cursor、-Codex、-Claude 或 -All"
}

try {
  Write-Host ""
  Write-Host "  $([char]0x1F680) $SkillDisplay — Skill 安装程序"
  Write-Host "  $([char]0x2500 * 41)"
  Write-Host ""

  Ensure-Source
  Test-SkillSource

  $homeDir = Get-UserHome
  if (-not $homeDir) {
    Fail "无法解析用户主目录（USERPROFILE / HOME 未设置）。"
  }

  if ($installCursor) {
    Install-One (Join-Path $homeDir ".cursor\skills") "Cursor"
  }
  if ($installCodex) {
    Install-Codex $homeDir
  }
  if ($installClaude) {
    Install-One (Join-Path $homeDir ".claude\skills") "Claude Code"
  }

  Write-Host ""
  Write-Host "  $([char]0x2500 * 41)"

  if ($Script:InstalledCount -gt 0 -and $Script:SkippedCount -eq 0) {
    Write-Host "  $([char]0x1F389) 安装成功！"
  }
  elseif ($Script:InstalledCount -gt 0 -and $Script:SkippedCount -gt 0) {
    Write-Host "  $([char]0x1F389) 安装成功（$($Script:SkippedCount) 个目标已存在，已跳过）"
  }
  elseif ($Script:SkippedCount -gt 0) {
    Write-Host "  $([char]0x2139)$([char]0xFE0F)  所有目标均已安装过，无需重复操作"
    Write-Hint "如需覆盖更新，请使用 -Force 参数"
  }

  Write-Host ""
  if ($installCodex -and $Script:InstalledCount -gt 0) {
    Write-Host ""
    Write-Info "Codex 用户请重启终端以加载新安装的 Skill"
  }
  Write-Host ""
}
finally {
  if ($DownloadTmp -and (Test-Path -LiteralPath $DownloadTmp)) {
    Remove-Item -LiteralPath $DownloadTmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
