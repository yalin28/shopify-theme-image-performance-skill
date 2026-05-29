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

$Script:SrcDir = $null
if ($PSScriptRoot) {
  try {
    $Script:SrcDir = (Resolve-Path (Join-Path $PSScriptRoot "..") -ErrorAction SilentlyContinue).Path
  }
  catch {
    $Script:SrcDir = $null
  }
}
if (-not $Script:SrcDir) {
  $Script:SrcDir = (Get-Location).Path
}
$DownloadTmp = $null
$Script:InstalledCount = 0
$Script:SkippedCount = 0

$SkillFiles = @("SKILL.md")
$OptionalDirs = @("agents")

function Write-Info([string]$Message)  { Write-Host "  [info] $Message" }
function Write-Step([string]$Message)  { Write-Host "  > $Message" }
function Write-Ok([string]$Message)    { Write-Host "  [ok] $Message" }
function Write-Warn([string]$Message)  { Write-Host "  [warn] $Message" }
function Write-Hint([string]$Message)  { Write-Host "  [hint] $Message" }

function Show-Usage {
  Write-Host "Usage: .\scripts\install.ps1 [options]"
  Write-Host ""
  Write-Host "Install this Skill into AI tool config directories on Windows PowerShell."
  Write-Host ""
  Write-Host "Options:"
  Write-Host "  -Cursor          Install to %USERPROFILE%\.cursor\skills\<skill-name>\"
  Write-Host "  -Codex           Install to %USERPROFILE%\.agents\skills\<skill-name>\ and %USERPROFILE%\.codex\skills\<skill-name>\"
  Write-Host "  -Claude          Install to %USERPROFILE%\.claude\skills\<skill-name>\"
  Write-Host "  -All             Install to Cursor + Codex + Claude Code"
  Write-Host "  -Force           Replace an existing install directory"
  Write-Host "  -Link            Create a directory symlink. Requires Developer Mode or admin rights."
  Write-Host "  -Help            Show help"
  Write-Host ""
  Write-Host "Examples:"
  Write-Host "  .\scripts\install.ps1 -Cursor -Force"
  Write-Host "  .\scripts\install.ps1 -Codex"
  Write-Host "  .\scripts\install.ps1 -Claude"
  Write-Host ""
  Write-Host "Remote install. Works in Windows PowerShell and cmd.exe:"
  Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -Command `"iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile shopify-install-temp.ps1; .\shopify-install-temp.ps1 -Cursor; Remove-Item shopify-install-temp.ps1`""
  Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -Command `"iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile shopify-install-temp.ps1; .\shopify-install-temp.ps1 -Codex; Remove-Item shopify-install-temp.ps1`""
  Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -Command `"iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile shopify-install-temp.ps1; .\shopify-install-temp.ps1 -Claude; Remove-Item shopify-install-temp.ps1`""
  Write-Host ""
  Write-Host "Note: This script is for Windows. Use install.sh for macOS, Linux, or Git Bash."
}

function Fail([string]$Message) {
  Write-Host ""
  Write-Host "  [error] $Message" -ForegroundColor Red
  exit 1
}

function Ensure-Source {
  if (Test-Path -LiteralPath (Join-Path $Script:SrcDir "SKILL.md") -PathType Leaf) {
    return
  }

  Write-Step "Local repository not found. Downloading Skill files from GitHub..."
  Write-Info "Source: ${GithubRepo}@${GithubRef}"
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
      # agents is optional.
    }
  }
  catch {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Fail "Failed to download Skill files. Check your network connection, repository, or ref."
  }

  $Script:SrcDir = $tmp
}

function Test-SkillSource {
  if (-not (Test-Path -LiteralPath (Join-Path $Script:SrcDir "SKILL.md") -PathType Leaf)) {
    Fail "SKILL.md was not found. Cannot continue."
  }
}

function Install-One([string]$DestRoot, [string]$Label = "") {
  $dest = Join-Path $DestRoot $SkillName

  if ($Label) {
    Write-Step "Installing to ${Label}..."
  }

  if (Test-Path -LiteralPath $dest) {
    if ($Force) {
      Remove-Item -LiteralPath $dest -Recurse -Force
    }
    else {
      Write-Warn "Path already exists: $dest"
      Write-Hint "The Skill is already installed there. Re-run with -Force to replace it."
      $Script:SkippedCount++
      return
    }
  }

  if (-not (Test-Path -LiteralPath $DestRoot)) {
    New-Item -ItemType Directory -Path $DestRoot -Force | Out-Null
  }

  if ($Link) {
    if ($DownloadTmp) {
      Fail "Remote download mode does not support -Link. Clone the repository first, then use -Link."
    }
    try {
      New-Item -ItemType SymbolicLink -Path $dest -Target $Script:SrcDir -Force | Out-Null
      Write-Ok "Installed via symlink -> $dest"
      $Script:InstalledCount++
      return
    }
    catch {
      Fail "Failed to create symlink: $($_.Exception.Message). Remove -Link, or enable Windows Developer Mode and run as administrator."
    }
  }

  New-Item -ItemType Directory -Path $dest -Force | Out-Null

  foreach ($file in $SkillFiles) {
    $src = Join-Path $Script:SrcDir $file
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
      Fail "Missing source file: $src"
    }
    Copy-Item -LiteralPath $src -Destination (Join-Path $dest $file) -Force
  }

  foreach ($dir in $OptionalDirs) {
    $srcDirPath = Join-Path $Script:SrcDir $dir
    if (Test-Path -LiteralPath $srcDirPath -PathType Container) {
      Copy-Item -LiteralPath $srcDirPath -Destination (Join-Path $dest $dir) -Recurse -Force
    }
  }

  Write-Ok "Installed -> $dest"
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

  Install-One $standardRoot "Codex (standard path)"
  if ($legacyRoot -ne $standardRoot) {
    Install-One $legacyRoot "Codex (compatibility path)"
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
  Fail "Choose an install target: -Cursor, -Codex, -Claude, or -All"
}

try {
  Write-Host ""
  Write-Host "  $SkillDisplay - Skill Installer"
  Write-Host "  -----------------------------------------"
  Write-Host ""

  Ensure-Source
  Test-SkillSource

  $homeDir = Get-UserHome
  if (-not $homeDir) {
    Fail "Could not resolve the user home directory. USERPROFILE and HOME are not set."
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
  Write-Host "  -----------------------------------------"

  if ($Script:InstalledCount -gt 0 -and $Script:SkippedCount -eq 0) {
    Write-Host "  [success] Installed successfully."
  }
  elseif ($Script:InstalledCount -gt 0 -and $Script:SkippedCount -gt 0) {
    Write-Host "  [success] Installed successfully. Skipped $($Script:SkippedCount) existing target(s)."
  }
  elseif ($Script:SkippedCount -gt 0) {
    Write-Host "  [info] All selected targets were already installed."
    Write-Hint "Use -Force to replace existing installs."
  }

  Write-Host ""
  if ($installCodex -and $Script:InstalledCount -gt 0) {
    Write-Host ""
    Write-Info "Restart your terminal so Codex can load the newly installed Skill."
  }
  Write-Host ""
}
finally {
  if ($DownloadTmp -and (Test-Path -LiteralPath $DownloadTmp)) {
    Remove-Item -LiteralPath $DownloadTmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
