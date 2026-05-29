#!/usr/bin/env bash
# Install shopify-theme-image-performance skill for Cursor, Codex, or Claude Code.
set -euo pipefail

SKILL_NAME="shopify-theme-image-performance"
SKILL_DISPLAY="Shopify Theme Image Performance"
GITHUB_REPO="${SKILL_INSTALL_REPO:-yalin28/shopify-theme-image-performance-skill}"
GITHUB_REF="${SKILL_INSTALL_REF:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/.." 2>/dev/null && pwd || pwd)"
DOWNLOAD_TMP=""

INSTALL_CURSOR=0
INSTALL_CODEX=0
INSTALL_CLAUDE=0
FORCE=0
USE_LINK=0
INSTALLED_COUNT=0
SKIPPED_COUNT=0

SKILL_FILES=(SKILL.md)
OPTIONAL_DIRS=(agents)

cleanup() {
  if [[ -n "${DOWNLOAD_TMP}" && -d "${DOWNLOAD_TMP}" ]]; then
    rm -rf "${DOWNLOAD_TMP}"
  fi
}
trap cleanup EXIT

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

  case "$(uname -s 2>/dev/null || true)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

line() {
  if plain_output; then
    echo "  -----------------------------------------"
  else
    echo "  ─────────────────────────────────────────"
  fi
}

info()  { if plain_output; then echo "  [info] $*"; else echo "  💬 $*"; fi; }
step()  { if plain_output; then echo "  > $*"; else echo "  ▸ $*"; fi; }
ok()    { if plain_output; then echo "  [ok] $*"; else echo "  ✅ $*"; fi; }
warn()  { if plain_output; then echo "  [warn] $*"; else echo "  ⚠️  $*"; fi; }
hint()  { if plain_output; then echo "  [hint] $*"; else echo "  💡 $*"; fi; }

target_args_for_powershell() {
  local args=()

  if [[ "${INSTALL_CURSOR}" -eq 1 && "${INSTALL_CODEX}" -eq 1 && "${INSTALL_CLAUDE}" -eq 1 ]]; then
    args+=("-All")
  else
    [[ "${INSTALL_CURSOR}" -eq 1 ]] && args+=("-Cursor")
    [[ "${INSTALL_CODEX}" -eq 1 ]] && args+=("-Codex")
    [[ "${INSTALL_CLAUDE}" -eq 1 ]] && args+=("-Claude")
  fi

  [[ "${FORCE}" -eq 1 ]] && args+=("-Force")

  printf "%s" "${args[*]}"
}

print_windows_powershell_install_command() {
  local target_args
  target_args="$(target_args_for_powershell)"
  local ps_cmd="powershell"
  if is_wsl; then
    ps_cmd="powershell.exe"
  fi

  cat >&2 <<EOF
  ${ps_cmd} -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_REF}/scripts/install.ps1 -OutFile shopify-install-temp.ps1; .\shopify-install-temp.ps1 ${target_args}; Remove-Item shopify-install-temp.ps1"
EOF
}

usage() {
  cat <<'EOF'
用法: ./scripts/install.sh [选项]

将本仓库中的 Skill 安装到 AI 工具的配置目录。

选项:
  --cursor          安装到 ~/.cursor/skills/<skill-name>/
  --codex           安装到 ~/.agents/skills/<skill-name>/，并兼容 ~/.codex/skills/<skill-name>/
  --claude          安装到 ~/.claude/skills/<skill-name>/
  --all             安装到 Cursor + Codex + Claude Code
  --force           覆盖已存在的安装目录
  --link            使用符号链接（适合本地开发本仓库）
  -h, --help        显示帮助

示例:
  ./scripts/install.sh --cursor --force
  ./scripts/install.sh --codex
  ./scripts/install.sh --claude

远程安装（从 GitHub 拉取 Skill 文件后安装，按平台选择）:
  curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --cursor
  curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --codex
  curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --claude

Windows 用户请使用 PowerShell 或 cmd.exe 运行 install.ps1（见 README）
EOF
}

die() {
  echo "" >&2
  if plain_output; then
    echo "  [error] $*" >&2
  else
    echo "  ❌ $*" >&2
  fi
  exit 1
}

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

guard_cursor_wsl() {
  if [[ "${INSTALL_CURSOR}" -ne 1 || "${SKILL_ALLOW_WSL_CURSOR:-}" == "1" ]]; then
    return 0
  fi

  if ! is_wsl; then
    return 0
  fi

  if plain_output; then
    cat >&2 <<'EOF'

  [error] 检测到当前命令运行在 WSL 中，已停止安装 Cursor Skill。

  WSL 的 ~/.cursor/skills 位于 Linux 子系统内，Windows 版 Cursor 不会读取该目录。
  请在 Windows PowerShell 中运行下面的命令：

EOF
    print_windows_powershell_install_command
    cat >&2 <<'EOF'
  若只想安装 Codex 或 Claude Code 到 WSL，请改用 --codex 或 --claude。
  如果你确实要安装给 WSL 内的 Linux 版 Cursor，可设置 SKILL_ALLOW_WSL_CURSOR=1 后重试。
EOF
  else
    cat >&2 <<'EOF'

  ❌ 检测到当前命令运行在 WSL 中，已停止安装 Cursor Skill。

  WSL 的 ~/.cursor/skills 位于 Linux 子系统内，Windows 版 Cursor 不会读取该目录。
  请在 Windows PowerShell 中运行下面的命令：

EOF
    print_windows_powershell_install_command
    cat >&2 <<'EOF'
  若只想安装 Codex 或 Claude Code 到 WSL，请改用 --codex 或 --claude。
  如果你确实要安装给 WSL 内的 Linux 版 Cursor，可设置 SKILL_ALLOW_WSL_CURSOR=1 后重试。
EOF
  fi
  exit 1
}

ensure_source() {
  if [[ -f "${SRC_DIR}/SKILL.md" ]]; then
    return 0
  fi

  step "未检测到本地仓库，正在从 GitHub 获取 Skill 文件..."
  info "来源: ${GITHUB_REPO}@${GITHUB_REF}"
  DOWNLOAD_TMP="$(mktemp -d)"
  local base="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_REF}"

  curl -fsSL "${base}/SKILL.md" -o "${DOWNLOAD_TMP}/SKILL.md" \
    || die "下载 SKILL.md 失败，请检查网络连接或仓库地址是否正确"

  mkdir -p "${DOWNLOAD_TMP}/agents"
  curl -fsSL "${base}/agents/openai.yaml" -o "${DOWNLOAD_TMP}/agents/openai.yaml" 2>/dev/null || true

  SRC_DIR="${DOWNLOAD_TMP}"
}

require_skill_source() {
  [[ -f "${SRC_DIR}/SKILL.md" ]] || die "未找到 SKILL.md，无法继续安装。"
}

install_one() {
  local dest_root="$1"
  local label="${2:-}"
  local dest="${dest_root}/${SKILL_NAME}"

  if [[ -n "${label}" ]]; then
    step "正在安装到 ${label}..."
  fi

  if [[ -e "${dest}" ]]; then
    if [[ "${FORCE}" -eq 1 ]]; then
      rm -rf "${dest}"
    else
      warn "该路径已存在: ${dest}"
      hint "Skill 之前已安装过，如需覆盖更新请添加 --force 参数重新运行"
      SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
      return 0
    fi
  fi

  mkdir -p "${dest_root}"

  if [[ "${USE_LINK}" -eq 1 ]]; then
    if [[ -n "${DOWNLOAD_TMP}" ]]; then
      die "远程下载模式不支持 --link，请先 git clone 仓库后再使用链接安装"
    fi
    ln -s "${SRC_DIR}" "${dest}"
    ok "已通过符号链接安装 -> ${dest}"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    return
  fi

  mkdir -p "${dest}"
  for f in "${SKILL_FILES[@]}"; do
    cp "${SRC_DIR}/${f}" "${dest}/${f}"
  done
  for d in "${OPTIONAL_DIRS[@]}"; do
    if [[ -d "${SRC_DIR}/${d}" ]]; then
      cp -R "${SRC_DIR}/${d}" "${dest}/"
    fi
  done
  ok "安装完成 -> ${dest}"
  INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
}

install_codex() {
  local standard_root="${CODEX_AGENT_SKILLS_DIR:-${HOME}/.agents/skills}"
  local legacy_root="${CODEX_HOME:-${HOME}/.codex}/skills"

  install_one "${standard_root}" "Codex (标准路径)"
  if [[ "${legacy_root}" != "${standard_root}" ]]; then
    install_one "${legacy_root}" "Codex (兼容路径)"
  fi
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    usage
    echo "" >&2
    die "请选择安装目标：--cursor、--codex、--claude 或 --all"
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cursor) INSTALL_CURSOR=1 ;;
      --codex) INSTALL_CODEX=1 ;;
      --claude) INSTALL_CLAUDE=1 ;;
      --all)
        INSTALL_CURSOR=1
        INSTALL_CODEX=1
        INSTALL_CLAUDE=1
        ;;
      --force) FORCE=1 ;;
      --link) USE_LINK=1 ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "未知参数: $1（使用 -h 查看帮助）"
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"

  echo ""
  if plain_output; then
    echo "  ${SKILL_DISPLAY} - Skill 安装程序"
  else
    echo "  🚀 ${SKILL_DISPLAY} — Skill 安装程序"
  fi
  line
  echo ""

  guard_cursor_wsl

  ensure_source
  require_skill_source

  if [[ "${INSTALL_CURSOR}" -eq 0 && "${INSTALL_CODEX}" -eq 0 && "${INSTALL_CLAUDE}" -eq 0 ]]; then
    die "请指定至少一个安装目标：--cursor、--codex、--claude 或 --all"
  fi

  if [[ "${INSTALL_CURSOR}" -eq 1 ]]; then
    install_one "$(cursor_dest_root)" "Cursor"
  fi
  if [[ "${INSTALL_CODEX}" -eq 1 ]]; then
    install_codex
  fi
  if [[ "${INSTALL_CLAUDE}" -eq 1 ]]; then
    install_one "${HOME}/.claude/skills" "Claude Code"
  fi

  echo ""
  line

  if [[ "${INSTALLED_COUNT}" -gt 0 && "${SKIPPED_COUNT}" -eq 0 ]]; then
    if plain_output; then
      echo "  [success] 安装成功！"
    else
      echo "  🎉 安装成功！"
    fi
  elif [[ "${INSTALLED_COUNT}" -gt 0 && "${SKIPPED_COUNT}" -gt 0 ]]; then
    if plain_output; then
      echo "  [success] 安装成功（${SKIPPED_COUNT} 个目标已存在，已跳过）"
    else
      echo "  🎉 安装成功（${SKIPPED_COUNT} 个目标已存在，已跳过）"
    fi
  elif [[ "${SKIPPED_COUNT}" -gt 0 ]]; then
    if plain_output; then
      echo "  [info] 所有目标均已安装过，无需重复操作"
    else
      echo "  ℹ️  所有目标均已安装过，无需重复操作"
    fi
    hint "如需覆盖更新，请使用 --force 参数"
  fi

  if [[ "${INSTALL_CODEX}" -eq 1 && "${INSTALLED_COUNT}" -gt 0 ]]; then
    echo ""
    info "Codex 用户请重启终端以加载新安装的 Skill"
  fi
  echo ""
}

main "$@"
