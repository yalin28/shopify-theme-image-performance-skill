#!/usr/bin/env bash
# Verify shopify-theme-image-performance skill installation.
set -euo pipefail

SKILL_NAME="shopify-theme-image-performance"
FOUND=0

is_wsl() {
  if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]]; then
    return 0
  fi

  [[ -r /proc/version ]] && grep -qiE "microsoft|wsl" /proc/version
}

is_windows_bash() {
  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

windows_path_to_posix() {
  local path="$1"

  if command -v cygpath >/dev/null 2>&1; then
    local converted
    if converted="$(cygpath -u "${path}" 2>/dev/null)" && [[ -n "${converted}" ]]; then
      printf "%s" "${converted}"
      return
    fi
  fi

  case "${path}" in
    [A-Za-z]:\\*)
      local drive
      local rest
      drive="$(printf "%s" "${path:0:1}" | tr "[:upper:]" "[:lower:]")"
      rest="${path:2}"
      rest="${rest//\\//}"
      printf "/%s%s" "${drive}" "${rest}"
      return
      ;;
  esac

  printf "%s" "${path}"
}

cursor_dest_root() {
  if is_windows_bash && [[ -n "${USERPROFILE:-}" ]]; then
    local user_profile
    user_profile="$(windows_path_to_posix "${USERPROFILE}")"
    if [[ -n "${user_profile}" ]]; then
      printf "%s/.cursor/skills" "${user_profile}"
      return
    fi
  fi

  printf "%s/.cursor/skills" "${HOME}"
}

plain_output() {
  if [[ "${SKILL_INSTALL_PLAIN_OUTPUT:-}" == "1" ]]; then
    return 0
  fi
  if [[ "${SKILL_INSTALL_EMOJI:-}" == "1" ]]; then
    return 1
  fi
  if is_wsl; then
    return 0
  fi
  is_windows_bash
}

missing_msg() { if plain_output; then echo "[missing] $*"; else echo "○ $*"; fi; }
error_msg()   { if plain_output; then echo "[error] $*"; else echo "✗ $*"; fi; }
ok_msg()      { if plain_output; then echo "[ok] $*"; else echo "✓ $*"; fi; }

check_dir() {
  local label="$1"
  local dir="$2"

  if [[ ! -d "${dir}" ]]; then
    missing_msg "${label}: 未安装 (${dir})"
    return
  fi

  local missing=0
  for f in SKILL.md; do
    if [[ ! -f "${dir}/${f}" ]]; then
      error_msg "${label}: 缺少 ${f} (${dir})"
      missing=1
    fi
  done

  if [[ ${missing} -eq 1 ]]; then
    return
  fi

  if ! grep -q "^name: ${SKILL_NAME}" "${dir}/SKILL.md" 2>/dev/null; then
    error_msg "${label}: SKILL.md 中 name 字段应为 ${SKILL_NAME} (${dir})"
    return
  fi

  ok_msg "${label}: ${dir}"
  FOUND=$((FOUND + 1))
}

echo "检查 Skill 安装: ${SKILL_NAME}"
echo ""

check_dir "Cursor（个人）" "$(cursor_dest_root)/${SKILL_NAME}"
check_dir "Codex（个人标准）" "${CODEX_AGENT_SKILLS_DIR:-${HOME}/.agents/skills}/${SKILL_NAME}"
check_dir "Codex（个人兼容）" "${CODEX_HOME:-${HOME}/.codex}/skills/${SKILL_NAME}"
check_dir "Claude Code（个人）" "${HOME}/.claude/skills/${SKILL_NAME}"

echo ""
if [[ ${FOUND} -gt 0 ]]; then
  echo "已检测到 ${FOUND} 处有效安装。若 Agent 未识别 Skill，请重启 IDE 或新开对话。"
  exit 0
fi

echo "未发现有效安装。请按目标平台运行: ./scripts/install.sh --cursor、--codex 或 --claude"
exit 1
