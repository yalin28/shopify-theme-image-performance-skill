#!/usr/bin/env bash
# Verify shopify-theme-image-performance skill installation.
set -euo pipefail

SKILL_NAME="shopify-theme-image-performance"
FOUND=0

check_dir() {
  local label="$1"
  local dir="$2"

  if [[ ! -d "${dir}" ]]; then
    echo "○ ${label}: 未安装 (${dir})"
    return
  fi

  local missing=0
  for f in SKILL.md examples.md; do
    if [[ ! -f "${dir}/${f}" ]]; then
      echo "✗ ${label}: 缺少 ${f} (${dir})"
      missing=1
    fi
  done

  if [[ ${missing} -eq 1 ]]; then
    return
  fi

  if ! grep -q "^name: ${SKILL_NAME}" "${dir}/SKILL.md" 2>/dev/null; then
    echo "✗ ${label}: SKILL.md 中 name 字段应为 ${SKILL_NAME} (${dir})"
    return
  fi

  echo "✓ ${label}: ${dir}"
  FOUND=$((FOUND + 1))
}

echo "检查 Skill 安装: ${SKILL_NAME}"
echo ""

check_dir "Cursor（个人）" "${HOME}/.cursor/skills/${SKILL_NAME}"
check_dir "Codex（个人）" "${CODEX_HOME:-${HOME}/.codex}/skills/${SKILL_NAME}"
check_dir "Claude Code（个人）" "${HOME}/.claude/skills/${SKILL_NAME}"

if [[ -f ".cursor/skills/${SKILL_NAME}/SKILL.md" ]]; then
  check_dir "当前项目" "$(pwd)/.cursor/skills/${SKILL_NAME}"
fi

echo ""
if [[ ${FOUND} -gt 0 ]]; then
  echo "已检测到 ${FOUND} 处有效安装。若 Agent 未识别 Skill，请重启 IDE 或新开对话。"
  exit 0
fi

echo "未发现有效安装。请运行: ./scripts/install.sh --all"
exit 1
