# shopify-theme-image-performance

[![GitHub](https://img.shields.io/github/repo/yalin28/shopify-theme-image-performance-skill)](https://github.com/yalin28/shopify-theme-image-performance-skill)

Cursor / Codex / Claude Code 共用的 **Agent Skill**：系统化优化 Shopify 主题 section/snippet 中的图片加载，在**不改变视觉布局**的前提下减少请求数与传输体积。

| 字段 | 值 |
|------|-----|
| Skill 名称 | `shopify-theme-image-performance` |
| 安装目录名 | `shopify-theme-image-performance`（与 `SKILL.md` 中 `name` 一致） |
| 仓库 | [yalin28/shopify-theme-image-performance-skill](https://github.com/yalin28/shopify-theme-image-performance-skill) |

## 适用场景

- Section / snippet 图片加载慢、原图直出
- PC/移动双 `<img>` + CSS 隐藏导致重复下载
- `img_url` 迁移到 `image_url` / `image_tag`
- 响应式 `sizes` / `widths`、`picture` 选型
- 首屏 LCP 与 `loading` / `fetchpriority` 策略

## 快速安装

### macOS / Linux / Git Bash

```bash
git clone https://github.com/yalin28/shopify-theme-image-performance-skill.git
cd shopify-theme-image-performance-skill
chmod +x scripts/install.sh scripts/verify-install.sh
./scripts/install.sh --all
./scripts/verify-install.sh
```

| 目标 | 命令 | 安装路径 |
|------|------|----------|
| Cursor（个人） | `./scripts/install.sh --cursor` | `~/.cursor/skills/shopify-theme-image-performance/` |
| Codex（个人） | `./scripts/install.sh --codex` | `~/.codex/skills/shopify-theme-image-performance/` |
| Claude Code | `./scripts/install.sh --claude` | `~/.claude/skills/shopify-theme-image-performance/` |
| 主题项目（团队） | `./scripts/install.sh --project /path/to/theme` | `.cursor/skills/shopify-theme-image-performance/` |
| 全部个人环境 | `./scripts/install.sh --all` | Cursor + Codex |

```bash
./scripts/install.sh --all --force      # 覆盖已有安装
./scripts/install.sh --link --cursor    # 符号链接（仅本地 clone 后可用）
```

**远程一键**（无需 clone，脚本会从 GitHub 下载 `SKILL.md` / `examples.md` 后安装）：

```bash
curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --all
```

### Windows（PowerShell）

```powershell
git clone https://github.com/yalin28/shopify-theme-image-performance-skill.git
cd shopify-theme-image-performance-skill
.\scripts\install.ps1 -All
.\scripts\verify-install.ps1
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
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -All   # 绕过执行策略
```

**远程一键**（仅下载 `install.ps1`，脚本会从 GitHub 拉取 Skill 文件后安装）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile $env:TEMP\install-skill.ps1; & $env:TEMP\install-skill.ps1 -All }"
```

**Git Bash on Windows**：也可 `./scripts/install.sh --all`（与 macOS 相同）。

**`-Link` 说明**：Windows 符号链接需开发者模式或管理员；远程一键模式不支持 `-Link`。

### Codex 官方 Skill Installer（跨平台）

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo yalin28/shopify-theme-image-performance-skill \
  --path . \
  --name shopify-theme-image-performance
```

Windows 可用 `py -3` 或 `python`。安装后**重启 Codex**。目标已存在时需先删除或改用本仓库 `install.sh` / `install.ps1 -Force`。

### 手动复制

<details>
<summary>macOS / Linux / Git Bash</summary>

```bash
SKILL=shopify-theme-image-performance
mkdir -p ~/.cursor/skills/$SKILL
cp SKILL.md examples.md ~/.cursor/skills/$SKILL/
cp -R agents ~/.cursor/skills/$SKILL/ 2>/dev/null || true
```

</details>

<details>
<summary>Windows（PowerShell）</summary>

```powershell
$skill = "shopify-theme-image-performance"
$dest = Join-Path $env:USERPROFILE ".cursor\skills\$skill"
New-Item -ItemType Directory -Path $dest -Force
Copy-Item SKILL.md, examples.md -Destination $dest
if (Test-Path agents) { Copy-Item agents -Destination $dest -Recurse }
```

</details>

## 验证安装

安装完成后应存在以下文件（至少一处）：

- `SKILL.md`（含 `name: shopify-theme-image-performance`）
- `examples.md`

```bash
./scripts/verify-install.sh          # macOS / Linux / Git Bash
```

```powershell
.\scripts\verify-install.ps1         # Windows PowerShell
```

若验证通过但 Agent 仍不触发 Skill：重启 IDE、新开对话，或显式提及 skill 名称（见下方使用方式）。

## 使用方式

在 **Shopify 主题项目**（非本 skill 仓库）中打开 Agent，例如：

- 「优化这个 section 的图片加载」
- 「按 shopify-theme-image-performance 分析 `sections/xxx.liquid`」
- 「确认，先做 P0」

**两阶段工作流（Skill 强制）：**

| 阶段 | Agent 行为 |
|------|------------|
| 分析 | 只读代码，输出 P0–Pn 清单，**不改文件** |
| 实施 | 用户明确确认某一优先级（如「确认，先做 P0」）后，才改该级别 |

## 常见问题

| 问题 | 处理 |
|------|------|
| `curl \| bash` 报错找不到 SKILL.md | 已修复：脚本会自动从 GitHub 下载；请用 README 中的完整 URL |
| PowerShell 禁止运行脚本 | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` 或使用 `-ExecutionPolicy Bypass` |
| 安装目录已存在 | 加 `--force`（bash）或 `-Force`（PowerShell） |
| Codex 看不到 Skill | 安装到 `~/.codex/skills/` 后重启 Codex |
| 团队共享 | 在主题仓库执行 `--project` / `-Project`，将 `.cursor/skills/` 提交进主题 git |

## 文件结构

```
shopify-theme-image-performance-skill/
├── SKILL.md                 # Agent 主指令（必需）
├── examples.md              # 真实改法参考
├── agents/openai.yaml       # Codex UI 元数据（可选）
├── scripts/
│   ├── install.sh           # macOS / Linux / Git Bash 安装
│   ├── install.ps1          # Windows PowerShell 安装
│   ├── verify-install.sh    # 安装验证（bash）
│   └── verify-install.ps1   # 安装验证（PowerShell）
├── LICENSE
└── README.md
```

## 相关依赖

建议在 Cursor / Codex 中启用 **Shopify MCP**，以便阶段 2 自动 `validate_theme`；无 MCP 时 Skill 会提示手动校验。

## License

MIT — 见 [LICENSE](LICENSE)
