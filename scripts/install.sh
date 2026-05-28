#!/usr/bin/env bash
# Install shopify-theme-image-performance skill for Cursor, Codex, Claude Code, or a project repo.
set -euo pipefail

SKILL_NAME="shopify-theme-image-performance"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

INSTALL_CURSOR=0
INSTALL_CODEX=0
INSTALL_CLAUDE=0
INSTALL_PROJECT=0
PROJECT_ROOT=""
FORCE=0
USE_LINK=0

SKILL_FILES=(SKILL.md examples.md)
OPTIONAL_DIRS=(agents)

usage() {
  cat <<'EOF'
用法: ./scripts/install.sh [选项]

将本仓库中的 Skill 安装到 AI 工具的配置目录。

选项:
  --cursor          安装到 ~/.cursor/skills/<skill-name>/
  --codex           安装到 ~/.codex/skills/<skill-name>/
  --claude          安装到 ~/.claude/skills/<skill-name>/
  --project [DIR]   安装到 <DIR>/.cursor/skills/<skill-name>/（默认当前目录）
  --all             安装到 Cursor + Codex（默认）
  --force           覆盖已存在的安装目录
  --link            使用符号链接（适合本地开发本仓库）
  -h, --help        显示帮助

示例:
  ./scripts/install.sh --all
  ./scripts/install.sh --cursor --force
  ./scripts/install.sh --project /path/to/my-shopify-theme
  ./scripts/install.sh --link --codex

远程一键安装:
  curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --all

Windows 用户请使用 PowerShell: .\\scripts\\install.ps1 -All（见 README）
EOF
}

die() {
  echo "错误: $*" >&2
  exit 1
}

require_skill_source() {
  [[ -f "${SRC_DIR}/SKILL.md" ]] || die "未找到 ${SRC_DIR}/SKILL.md，请在仓库根目录运行此脚本。"
}

install_one() {
  local dest_root="$1"
  local dest="${dest_root}/${SKILL_NAME}"

  if [[ -e "${dest}" ]]; then
    if [[ "${FORCE}" -eq 1 ]]; then
      rm -rf "${dest}"
    else
      die "目标已存在: ${dest}（使用 --force 覆盖）"
    fi
  fi

  mkdir -p "${dest_root}"

  if [[ "${USE_LINK}" -eq 1 ]]; then
    ln -s "${SRC_DIR}" "${dest}"
    echo "已链接 -> ${dest}"
    return
  fi

  mkdir -p "${dest}"
  for f in "${SKILL_FILES[@]}"; do
    cp "${SRC_DIR}/${f}" "${dest}/${f}"
  done
  for d in "${OPTIONAL_DIRS[@]}"; do
    if [[ -d "${SRC_DIR}/${d}" ]]; then
      cp -R "${SRC_DIR}/${d}" "${dest}/${d}"
    fi
  done
  echo "已安装 -> ${dest}"
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    INSTALL_CURSOR=1
    INSTALL_CODEX=1
    return
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cursor) INSTALL_CURSOR=1 ;;
      --codex) INSTALL_CODEX=1 ;;
      --claude) INSTALL_CLAUDE=1 ;;
      --project)
        INSTALL_PROJECT=1
        shift
        if [[ $# -gt 0 && "$1" != --* ]]; then
          PROJECT_ROOT="$1"
          shift
        fi
        ;;
      --all)
        INSTALL_CURSOR=1
        INSTALL_CODEX=1
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
  require_skill_source

  if [[ "${INSTALL_CURSOR}" -eq 0 && "${INSTALL_CODEX}" -eq 0 && "${INSTALL_CLAUDE}" -eq 0 && "${INSTALL_PROJECT}" -eq 0 ]]; then
    die "请指定至少一个目标：--cursor、--codex、--claude、--project 或 --all"
  fi

  if [[ "${INSTALL_CURSOR}" -eq 1 ]]; then
    install_one "${HOME}/.cursor/skills"
  fi
  if [[ "${INSTALL_CODEX}" -eq 1 ]]; then
    install_one "${CODEX_HOME:-${HOME}/.codex}/skills"
  fi
  if [[ "${INSTALL_CLAUDE}" -eq 1 ]]; then
    install_one "${HOME}/.claude/skills"
  fi
  if [[ "${INSTALL_PROJECT}" -eq 1 ]]; then
    local root="${PROJECT_ROOT:-$(pwd)}"
    install_one "${root}/.cursor/skills"
  fi

  echo ""
  echo "完成。在 Cursor / Codex 中打开 Shopify 主题项目后，可对 Agent 说："
  echo "  「按 shopify-theme-image-performance 分析这个 section 的图片加载」"
  if [[ "${INSTALL_CODEX}" -eq 1 ]]; then
    echo "Codex 用户：安装后请重启 Codex 以加载新 Skill。"
  fi
}

main "$@"
