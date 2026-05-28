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
    Write-Host "○ ${Label}: 未安装 ($Dir)"
    return
  }

  $missing = @("SKILL.md") | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $Dir $_) -PathType Leaf)
  }
  if ($missing.Count -gt 0) {
    Write-Host "✗ ${Label}: 缺少 $($missing -join ', ') ($Dir)"
    return
  }

  $nameOk = Select-String -LiteralPath (Join-Path $Dir "SKILL.md") -Pattern "^name: $SkillName" -Quiet
  if (-not $nameOk) {
    Write-Host "✗ ${Label}: SKILL.md 中 name 字段应为 $SkillName ($Dir)"
    return
  }

  Write-Host "✓ ${Label}: $Dir"
  $script:Found++
}

$homeDir = Get-UserHome
Write-Host "检查 Skill 安装: $SkillName"
Write-Host ""

Test-Install "Cursor（个人）" (Join-Path $homeDir ".cursor\skills\$SkillName")
$codexStandardRoot = if ($env:CODEX_AGENT_SKILLS_DIR) { $env:CODEX_AGENT_SKILLS_DIR } else { Join-Path $homeDir ".agents\skills" }
Test-Install "Codex（个人标准）" (Join-Path $codexStandardRoot $SkillName)
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeDir ".codex" }
Test-Install "Codex（个人兼容）" (Join-Path $codexHome "skills\$SkillName")
Test-Install "Claude Code（个人）" (Join-Path $homeDir ".claude\skills\$SkillName")

Write-Host ""
if ($Found -gt 0) {
  Write-Host "已检测到 $Found 处有效安装。若 Agent 未识别 Skill，请重启 IDE 或新开对话。"
  exit 0
}

Write-Host "未发现有效安装。请按目标平台运行: .\scripts\install.ps1 -Cursor、-Codex 或 -Claude"
exit 1
