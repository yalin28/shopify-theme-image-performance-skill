#!/usr/bin/env bash
# Install shopify-theme-image-performance skill for Cursor, Codex, or Claude Code.
set -euo pipefail

SKILL_NAME="shopify-theme-image-performance"
GITHUB_REPO="${SKILL_INSTALL_REPO:-yalin28/shopify-theme-image-performance-skill}"
GITHUB_REF="${SKILL_INSTALL_REF:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/.." 2>/dev/null && pwd || pwd)"
DOWNLOAD_TMP=""

INSTALL_CURSOR=0
INSTALL_CODEX=0
INSTALL_CLAUDE=0
FORCE=0
USE_LINK=0

SKILL_FILES=(SKILL.md examples.md)
OPTIONAL_DIRS=(agents)

cleanup() {
  if [[ -n "${DOWNLOAD_TMP}" && -d "${DOWNLOAD_TMP}" ]]; then
    rm -rf "${DOWNLOAD_TMP}"
  fi
}
trap cleanup EXIT

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

Windows 用户请使用 PowerShell: .\scripts\install.ps1 -Cursor / -Codex / -Claude（见 README）
EOF
}

die() {
  echo "错误: $*" >&2
  exit 1
}

ensure_source() {
  if [[ -f "${SRC_DIR}/SKILL.md" ]]; then
    return 0
  fi

  echo "未检测到本地仓库，正在从 GitHub 获取 Skill 文件（${GITHUB_REPO}@${GITHUB_REF}）..." >&2
  DOWNLOAD_TMP="$(mktemp -d)"
  local base="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_REF}"

  curl -fsSL "${base}/SKILL.md" -o "${DOWNLOAD_TMP}/SKILL.md" \
    || die "下载 SKILL.md 失败，请检查网络或仓库地址"
  curl -fsSL "${base}/examples.md" -o "${DOWNLOAD_TMP}/examples.md" \
    || die "下载 examples.md 失败"

  mkdir -p "${DOWNLOAD_TMP}/agents"
  curl -fsSL "${base}/agents/openai.yaml" -o "${DOWNLOAD_TMP}/agents/openai.yaml" 2>/dev/null || true

  SRC_DIR="${DOWNLOAD_TMP}"
}

require_skill_source() {
  [[ -f "${SRC_DIR}/SKILL.md" ]] || die "未找到 SKILL.md。"
  [[ -f "${SRC_DIR}/examples.md" ]] || die "未找到 examples.md。"
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
    if [[ -n "${DOWNLOAD_TMP}" ]]; then
      die "远程下载模式不支持 --link，请先 git clone 仓库后再链接安装"
    fi
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
      cp -R "${SRC_DIR}/${d}" "${dest}/"
    fi
  done
  echo "已安装 -> ${dest}"
}

install_codex() {
  local standard_root="${CODEX_AGENT_SKILLS_DIR:-${HOME}/.agents/skills}"
  local legacy_root="${CODEX_HOME:-${HOME}/.codex}/skills"

  install_one "${standard_root}"
  if [[ "${legacy_root}" != "${standard_root}" ]]; then
    install_one "${legacy_root}"
  fi
}

parse_args() {
  if [[ $# -eq 0 ]]; then
    usage
    echo "" >&2
    die "请明确选择安装目标：--cursor、--codex、--claude 或 --all"
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
  ensure_source
  require_skill_source

  if [[ "${INSTALL_CURSOR}" -eq 0 && "${INSTALL_CODEX}" -eq 0 && "${INSTALL_CLAUDE}" -eq 0 ]]; then
    die "请指定至少一个目标：--cursor、--codex、--claude 或 --all"
  fi

  if [[ "${INSTALL_CURSOR}" -eq 1 ]]; then
    install_one "${HOME}/.cursor/skills"
  fi
  if [[ "${INSTALL_CODEX}" -eq 1 ]]; then
    install_codex
  fi
  if [[ "${INSTALL_CLAUDE}" -eq 1 ]]; then
    install_one "${HOME}/.claude/skills"
  fi
  echo ""
  echo "完成。验证: ./scripts/verify-install.sh"
  echo "使用: 在 Shopify 主题项目中对 Agent 说「按 shopify-theme-image-performance 分析这个 section 的图片加载」"
  if [[ "${INSTALL_CODEX}" -eq 1 ]]; then
    echo "Codex: 安装后请重启以加载新 Skill。"
  fi
}

main "$@"
