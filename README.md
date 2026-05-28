# shopify-theme-image-performance

Cursor / Codex / Claude Code 共用的 **Agent Skill**：系统化优化 Shopify 主题 section/snippet 中的图片加载，在**不改变视觉布局**的前提下减少请求数与传输体积。

| 字段 | 值 |
|------|-----|
| Skill 名称 | `shopify-theme-image-performance` |
| 安装目录名 | `shopify-theme-image-performance`（与 `SKILL.md` 中 `name` 一致） |
| 仓库目录名 | `shopify-theme-image-performance-skill`（仅用于区分 Git 仓库类型） |

## 适用场景

- Section / snippet 图片加载慢、原图直出
- PC/移动双 `<img>` + CSS 隐藏导致重复下载
- `img_url` 迁移到 `image_url` / `image_tag`
- 响应式 `sizes` / `widths`、`picture` 选型
- 首屏 LCP 与 `loading` / `fetchpriority` 策略

## 快速安装

### macOS / Linux / Git Bash

克隆本仓库后执行：

```bash
git clone https://github.com/yalin28/shopify-theme-image-performance-skill.git
cd shopify-theme-image-performance-skill
chmod +x scripts/install.sh
./scripts/install.sh --all
```

| 目标 | 命令 | 安装路径 |
|------|------|----------|
| Cursor（个人） | `./scripts/install.sh --cursor` | `~/.cursor/skills/shopify-theme-image-performance/` |
| Codex（个人） | `./scripts/install.sh --codex` | `~/.codex/skills/shopify-theme-image-performance/` |
| Claude Code | `./scripts/install.sh --claude` | `~/.claude/skills/shopify-theme-image-performance/` |
| 主题项目（团队） | `./scripts/install.sh --project /path/to/theme` | `.cursor/skills/shopify-theme-image-performance/` |
| 全部个人环境 | `./scripts/install.sh --all` | Cursor + Codex |

```bash
./scripts/install.sh --all --force
./scripts/install.sh --link --cursor   # 符号链接，改 SKILL.md 即时生效
```

远程一键：

```bash
curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --all
```

### Windows（PowerShell）

在 **PowerShell**（非 CMD）中进入仓库目录：

```powershell
git clone https://github.com/yalin28/shopify-theme-image-performance-skill.git
cd shopify-theme-image-performance-skill
.\scripts\install.ps1 -All
```

| 目标 | 命令 | 安装路径 |
|------|------|----------|
| Cursor（个人） | `.\scripts\install.ps1 -Cursor` | `%USERPROFILE%\.cursor\skills\shopify-theme-image-performance\` |
| Codex（个人） | `.\scripts\install.ps1 -Codex` | `%USERPROFILE%\.codex\skills\shopify-theme-image-performance\` |
| Claude Code | `.\scripts\install.ps1 -Claude` | `%USERPROFILE%\.claude\skills\shopify-theme-image-performance\` |
| 主题项目（团队） | `.\scripts\install.ps1 -Project C:\path\to\theme` | `.cursor\skills\shopify-theme-image-performance\` |
| 全部个人环境 | `.\scripts\install.ps1 -All` | Cursor + Codex |

```powershell
.\scripts\install.ps1 -All -Force
.\scripts\install.ps1 -Help
```

若提示「无法加载，因为在此系统上禁止运行脚本」，可先执行：

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

或单次绕过策略：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -All
```

**`-Link` 说明**：Windows 创建目录符号链接通常需要「开发者模式」或管理员权限；失败时请去掉 `-Link`，使用默认复制安装。

远程一键（PowerShell）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile $env:TEMP\install-skill.ps1; & $env:TEMP\install-skill.ps1 -All }"
```

**Git Bash on Windows**：也可使用 `./scripts/install.sh --all`（路径与 macOS 相同，写到 `%USERPROFILE%` 下）。

### Codex 官方 Skill Installer（跨平台）

若已安装 Codex 内置的 `skill-installer`，可从 GitHub 拉取：

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo yalin28/shopify-theme-image-performance-skill \
  --path . \
  --name shopify-theme-image-performance
```

Windows 上若 `python3` 不可用，可尝试 `py -3` 或 `python`。安装后**重启 Codex**。

### 手动复制

**macOS / Linux / Git Bash：**

```bash
SKILL=shopify-theme-image-performance
mkdir -p ~/.cursor/skills/$SKILL
cp SKILL.md examples.md ~/.cursor/skills/$SKILL/
cp -R agents ~/.cursor/skills/$SKILL/ 2>/dev/null || true
```

**Windows（PowerShell）：**

```powershell
$skill = "shopify-theme-image-performance"
$dest = Join-Path $env:USERPROFILE ".cursor\skills\$skill"
New-Item -ItemType Directory -Path $dest -Force
Copy-Item SKILL.md, examples.md -Destination $dest
if (Test-Path agents) { Copy-Item agents -Destination $dest -Recurse }
```

## 使用方式

在 Shopify 主题项目中打开 Agent，例如：

- 「优化这个 section 的图片加载」
- 「按 shopify-theme-image-performance 分析 `sections/rolling-list.liquid`」
- 「确认，先做 P0」

**两阶段工作流（Skill 强制）：**

1. **分析** — 只读代码，输出 P0–Pn 清单，**不改文件**
2. **实施** — 用户明确确认某一优先级后，才做该级别改动

## 文件结构

```
shopify-theme-image-performance-skill/
├── SKILL.md              # Agent 主指令（必需）
├── examples.md           # 真实改法参考（solution-img、bf-banner）
├── agents/
│   └── openai.yaml       # Codex UI 元数据
├── scripts/
│   ├── install.sh        # macOS / Linux / Git Bash
│   └── install.ps1       # Windows PowerShell
├── LICENSE
└── README.md
```

## 相关依赖

建议在 Cursor / Codex 中启用 **Shopify MCP**（`validate_theme` 验证 Liquid 改动）。

## License

MIT — 见 [LICENSE](LICENSE)
