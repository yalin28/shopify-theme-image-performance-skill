# shopify-theme-image-performance

Cursor / Codex / Claude Code 共用的 **Agent Skill**：系统化优化 Shopify 主题 section/snippet 中的图片加载，在**不改变视觉布局**的前提下减少请求数与传输体积。

## 适用场景

- Section / snippet 图片加载慢、原图直出
- PC/移动双 `<img>` + CSS 隐藏导致重复下载
- `img_url` 迁移到 `image_url` / `image_tag`
- 响应式 `sizes` / `widths`、`picture` 选型
- 首屏 LCP 与 `loading` / `fetchpriority` 策略

## 安装

> **⚠️ 请根据你的操作系统选择对应的安装命令。**
> - **macOS / Linux**：使用下方 `curl | bash` 命令
> - **Windows（PowerShell / cmd.exe / Windows Terminal）**：使用下方 `powershell ...` 命令
> - **Windows（Git Bash / MSYS2）**：使用 `curl | bash` 命令（与 macOS / Linux 相同）
>
> 如果在错误的系统上运行了另一个平台的命令（例如在 Mac 上运行 `powershell ...`），终端会直接报 `command not found`，这是正常现象——请切换到正确的命令即可。

### macOS / Linux / Git Bash

Cursor：

```bash
curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --cursor
```

Codex：

```bash
curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --codex
```

Claude Code：

```bash
curl -fsSL https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.sh | bash -s -- --claude
```

### Windows（PowerShell / cmd.exe）

以下命令在 PowerShell 和 cmd.exe 中均可直接运行（Windows 自带 `powershell.exe`）。

Cursor：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'install-skill.ps1')); & ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'install-skill.ps1')) -Cursor }"
```

Codex：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'install-skill.ps1')); & ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'install-skill.ps1')) -Codex }"
```

Claude Code：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/yalin28/shopify-theme-image-performance-skill/main/scripts/install.ps1 -OutFile ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'install-skill.ps1')); & ([IO.Path]::Combine([IO.Path]::GetTempPath(), 'install-skill.ps1')) -Claude }"
```

### Windows 各终端兼容性

| 终端 | 安装方式 | 说明 |
|------|---------|------|
| PowerShell 5.x / 7.x | 上方 `powershell ...` 命令 | Windows 自带，推荐 |
| cmd.exe | 上方 `powershell ...` 命令 | cmd 中可直接调用 `powershell` |
| Windows Terminal | 上方 `powershell ...` 命令 | 取决于默认 Profile（PowerShell 或 cmd） |
| Git Bash / MSYS2 | 上方 `curl \| bash` 命令 | 自动解析 `%USERPROFILE%` 路径 |
| WSL | 上方 `curl \| bash` 命令 | 安装 Cursor 时会提示改用 PowerShell |

## 安装位置

| 平台 | 安装目录 |
|------|----------|
| Cursor | `~/.cursor/skills/shopify-theme-image-performance/` |
| Codex | `~/.agents/skills/shopify-theme-image-performance/` + `~/.codex/skills/shopify-theme-image-performance/` |
| Claude Code | `~/.claude/skills/shopify-theme-image-performance/` |

安装后建议重启对应 IDE / Agent，新开对话后使用。

## 使用方式

在 Shopify 主题项目中打开 Agent，例如：

- 「优化这个 section 的图片加载」
- 「按 shopify-theme-image-performance 分析 `sections/xxx.liquid`」
- 「确认，先做 P0」

Skill 会按两阶段执行：

| 阶段 | Agent 行为 |
|------|------------|
| 分析 | 只读代码，输出 P0–Pn 清单，不改文件 |
| 实施 | 用户明确确认某一优先级后，只实施该级别 |

## 常见问题

| 问题 | 处理 |
|------|------|
| Mac/Linux 上运行 `powershell ...` 报 `command not found` | 这是 Windows 专用命令，请改用上方 macOS / Linux 的 `curl \| bash` 命令 |
| 安装目录已存在 | 添加 `--force`（bash）或 `-Force`（PowerShell）参数覆盖安装 |
| PowerShell 禁止运行脚本 | 使用 README 中的 `-ExecutionPolicy Bypass` 命令 |
| Windows Cursor 看不到 Skill，终端显示安装到 `/home/.../.cursor/skills` | 这是在 WSL 中运行了 bash 安装命令；Windows 版 Cursor 不读取 WSL 目录。请改用 PowerShell 命令 |
| Codex 看不到 Skill | 确认 `~/.agents/skills/` 和兼容路径 `~/.codex/skills/`，然后重启 Codex |
| Agent 没有自动触发 | 新开对话，或显式提及 `shopify-theme-image-performance` |

## 相关依赖

阶段 2 校验按以下顺序自动降级，**任一可用即可**：

1. Shopify MCP（推荐）：在 Cursor / Codex 中启用后，Skill 自动调用 `validate_theme`。
2. Shopify CLI 本地校验：`shopify theme check`（未安装可 `brew install shopify-cli` 或 `npm i -g @shopify/cli @shopify/theme`）。
3. IDE Liquid / Theme Check 插件保存时自动校验。
4. 上述均不可用时，Skill 会显式说明"未自动校验"并做人工 diff 检查。

## License

[MIT](LICENSE)
