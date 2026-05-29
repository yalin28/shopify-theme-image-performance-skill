# shopify-theme-image-performance

Cursor / Codex / Claude Code 共用的 **Agent Skill**：系统化优化 Shopify 主题 section/snippet 中的图片加载，在**不改变视觉布局**的前提下减少请求数与传输体积。

## 适用场景

- Section / snippet 图片加载慢、原图直出
- PC/移动双 `<img>` + CSS 隐藏导致重复下载
- `img_url` 迁移到 `image_url` / `image_tag`
- 响应式 `sizes` / `widths`、`picture` 选型
- 首屏 LCP 与 `loading` / `fetchpriority` 策略

## 安装

选择一个目标平台安装。每个代码块都只有一条可直接执行的命令，方便使用 GitHub 的复制按钮。

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

### Windows PowerShell

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

Windows Cursor 推荐使用上面的 PowerShell 命令。Windows 输出默认使用 `[ok]`、`[warn]` 等 ASCII 状态标记，避免 cmd / PowerShell 旧终端 emoji 乱码。Git Bash 会自动解析到 `%USERPROFILE%\.cursor\skills`；WSL 会被 bash 安装脚本拦截，因为 Windows 版 Cursor 不读取 WSL 的 `~/.cursor/skills`。

如果复制错平台命令，安装脚本会尽量停止并回显当前系统应使用的正确命令：WSL 中安装 Windows Cursor 会提示 PowerShell 命令；macOS / Linux / Git Bash 中调用 `install.ps1` 会提示 `curl | bash` 命令。

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
| 安装目录已存在 | 删除旧目录后，重新运行对应平台的远程安装命令 |
| PowerShell 禁止运行脚本 | 使用 README 中的 `-ExecutionPolicy Bypass` 命令 |
| 复制了另一个系统的安装命令 | 重新复制当前平台对应的命令；脚本能运行到平台检测时会直接回显正确命令 |
| Windows Cursor 看不到 Skill，终端显示安装到 `/home/.../.cursor/skills` | 这是在 WSL 中运行了 bash 安装命令；Windows 版 Cursor 不读取 WSL 目录。请改用 Windows PowerShell 的 `install.ps1 -Cursor -Force` 命令 |
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
