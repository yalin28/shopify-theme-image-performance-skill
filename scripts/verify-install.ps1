# Verify shopify-theme-image-performance skill installation.
#Requires -Version 5.1
$ErrorActionPreference = "Continue"

$SkillName = "shopify-theme-image-performance"
$Found = 0

function Get-UserHome {
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  return $env:HOME
}

function Test-Install([string]$Label, [string]$Dir) {
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) {
    Write-Host "[missing] ${Label}: not installed ($Dir)"
    return
  }

  $missing = @("SKILL.md") | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $Dir $_) -PathType Leaf)
  }
  if ($missing.Count -gt 0) {
    Write-Host "[error] ${Label}: missing $($missing -join ', ') ($Dir)"
    return
  }

  $nameOk = Select-String -LiteralPath (Join-Path $Dir "SKILL.md") -Pattern "^name: $SkillName" -Quiet
  if (-not $nameOk) {
    Write-Host "[error] ${Label}: SKILL.md name should be $SkillName ($Dir)"
    return
  }

  Write-Host "[ok] ${Label}: $Dir"
  $script:Found++
}

$homeDir = Get-UserHome
Write-Host "Checking Skill install: $SkillName"
Write-Host ""

Test-Install "Cursor (personal)" (Join-Path $homeDir ".cursor\skills\$SkillName")
$codexStandardRoot = if ($env:CODEX_AGENT_SKILLS_DIR) { $env:CODEX_AGENT_SKILLS_DIR } else { Join-Path $homeDir ".agents\skills" }
Test-Install "Codex (personal standard)" (Join-Path $codexStandardRoot $SkillName)
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeDir ".codex" }
Test-Install "Codex (personal compatibility)" (Join-Path $codexHome "skills\$SkillName")
Test-Install "Claude Code (personal)" (Join-Path $homeDir ".claude\skills\$SkillName")

Write-Host ""
if ($Found -gt 0) {
  Write-Host "Found $Found valid install(s). Restart the IDE or start a new chat if the Agent does not detect the Skill."
  exit 0
}

Write-Host "No valid install found. Run .\scripts\install.ps1 -Cursor, -Codex, or -Claude for your target tool."
exit 1
