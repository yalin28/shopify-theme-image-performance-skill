---
name: shopify-theme-image-performance
description: >-
  Optimizes Shopify theme section/snippet image loading: audit CSS vs CDN rules,
  replace dual PC/mobile img with picture, image_url/image_tag srcset/sizes,
  lazy/fetchpriority, minimal surgical diffs. Use when optimizing section load
  speed, responsive images, img_url migration, picture element, sizes/widths,
  图片优化, 加载速度, solution-img/bf-banner style refactors on Liquid sections.
  ALWAYS analyze and list P0-Pn priorities first without editing; only implement
  after user confirms, one priority level at a time.
---

# Shopify 主题图片性能优化

## 目标

在**不改变视觉布局**的前提下，减少图片 HTTP 请求数与传输体积。改动必须 surgical：只动图片相关代码，不 refactor 相邻逻辑。

## 交互门禁（必须遵守）

**默认两阶段，禁止跳步：**

| 阶段 | 触发 | 允许 | 禁止 |
|------|------|------|------|
| **阶段 1：分析** | 用户提出优化请求 | 读代码/CSS、盘点图片、输出 P0–Pn 清单与方案 | **修改任何文件** |
| **阶段 2：实施** | 用户**明确确认**要做某一优先级 | 仅实施用户确认的那一个 Px | 一次性改多个优先级；未确认就改代码 |

**硬规则：**

1. **先分析、后修改** — 首次响应只做优先级盘点，不主动改文件
2. **用户确认后才改** — 用户说「开始 P0」「确认 P0」等明确指令后，才进入阶段 2
3. **逐级实施** — 必须 P0 → P1 → P2 … 顺序；当前级别验证完成并获用户确认后，才进入下一级
4. **用户只确认 P0** — 只做 P0，P1/P2 留在「待做清单」，不得顺带修改
5. **用户要求「全部优化」** — 仍按 P0 先做，完成后汇报并等待确认再做 P1（不可一轮全改）

**阶段 1 结束语模板：**

> 以上为分析结果，尚未修改代码。请确认从哪个优先级开始（如「确认，先做 P0」）。

## 执行流程

```
阶段 1 — 分析（只读）
  1. 读 section + 关联 CSS/assets + template 用法
  2. 盘点所有图片点 → 识别反模式
  3. 从 CSS 推导各图片点的 sizes/widths 方案（写在分析里，不写进文件）
  4. 按 P0/P1/P2 排序，输出完整清单
  5. 等待用户确认

阶段 2 — 实施（用户确认后）
  1. 只改用户确认的那一个 Px
  2. 实施最小 diff
  3. validate_theme（Shopify MCP）
  4. 输出：改了什么、未改什么、DevTools 对比点、预估收益
  5. 询问是否继续下一优先级
```

## 第一步：识别反模式（按危害排序）

| 反模式 | 问题 |
|--------|------|
| PC/移动双 `<img>` + `hideMobile`/`hideDesktop` | 隐藏图仍会下载 |
| `img_url` 或 `img_url: 'small' \| replace: '_small', ''` | 已废弃，实际下原图 |
| `image_url` 无 `width` / 裸 `<img src=` | 原图直出 |
| `sizes="auto"` 或 `100vw` 未扣 padding/max-width | CDN 尺寸与 CSS 不符 |
| 无 `loading` / 首屏以下仍 eager | 浪费首屏带宽 |
| 改 `noscript`/schema/无关 JS | 超出范围，易引入回归 |

## 第二步：从 CSS 推导 CDN 规则（必做）

**禁止**凭猜测写 `sizes`。必须对照：

- 元素实际 `width`/`height`/`max-width`/`padding`/`gap`
- 断点（记录 exact px，如 749/750/768）
- 容器 `max-width`（如 `aosu-product-card` 1360px）
- 2x 视网膜：`widths` 上限 ≈ 渲染宽 × 2

常用公式：

```liquid
assign mobile_sizes = 'calc(100vw - [mobile_padding_total]px)'
assign desktop_sizes = '(min-width: [bp+1]px) min([content_max]px, calc(100vw - [pc_padding_total]px))'
assign split_sizes = '(min-width: [bp+1]px) calc((min([content_max]px, 100vw - [padding]px) - [gap]px) / 2)'
```

全宽 Banner：`sizes: '100vw'`（无 padding 时）。

## 第三步：标准修复模式

### 选型：`picture` 还是 `image_tag`？

**先看组件代码/schema，再看 CSS 尺寸——两者解决不同问题：**

| 判断依据 | 选用方案 | 说明 |
|----------|----------|------|
| PC/移动使用**不同图片资源**（如 `image` + `mobile_image`、双 `<img>` + CSS 隐藏） | **A. `<picture>` + `<source media>`** | 不同端不同 `srcset`，避免隐藏图仍被下载 |
| PC/移动**同一张图**，仅 CSS 改变显示尺寸 | **B. `image_tag` + `sizes` + `widths`** | 单资源响应式 CDN，不必 `<picture>` |
| 极小固定尺寸装饰图（如角标/贴图 <100px），无独立移动图 | **B 的简化版**：裸 `<img>` + `image_url: width:` + `loading` | 显示尺寸固定且源文件常已很小；不必 srcset |

**决策步骤：**

1. grep schema / Liquid：是否存在 `mobile_image`、`image_mobile` 等独立字段，或 PC/移动各渲染一个 `<img>`
2. 若**是** → 模式 A；`<source media>` 断点必须与 CSS 隐藏断点一致
3. 若**否**（同一 `image_picker` / 同一变量）→ 模式 B；从 CSS 推导 `sizes`/`widths`
4. 模式 B 下，若渲染宽固定且极小、收益可忽略 → 可降级为单 URL（仍须 `image_url: width:`，禁止原图直出）

**常见误判：** PC/移动布局不同（横排 vs 纵排）、显示宽不同，但**图源相同** → 仍用模式 B，**不要**上 `<picture>`。

### A. PC/移动不同图 → `<picture>`

```liquid
<picture>
  {%- if mobile_image != blank -%}
    <source
      media="(max-width: 749px)"
      srcset="{% for w in mobile_widths %}{{ mobile_image | image_url: width: w }} {{ w }}w{% unless forloop.last %}, {% endunless %}{% endfor %}"
      sizes="{{ mobile_sizes }}"
    >
  {%- endif -%}
  {{-
    desktop_image
    | image_url: width: desktop_max
    | image_tag:
      class: '...',
      loading: image_loading,
      fetchpriority: image_fetchpriority,
      sizes: desktop_sizes,
      widths: desktop_widths,
      alt: alt_text
  -}}
</picture>
```

- `<source>` 的 `media` 必须与 CSS 隐藏断点**一致**
- `<img>` 的 `sizes` 给 PC；`<source>` 的 `sizes` 给移动
- 移动图未配时：`default:` fallback 到 desktop，且可不输出 `<source>`
- 布局：必要时加 `#shopify-section-{{ section.id }} ... picture { display: contents; }`

### B. 单图多尺寸 → `image_tag` + `widths`

```liquid
{{-
  image
  | image_url: width: max_width
  | image_tag:
    loading: 'lazy',
    fetchpriority: 'low',
    sizes: '(min-width: 768px) 150px, 180px',
    widths: '150,180,300,360',
    alt: alt_text
-}}
```

### C. loading / fetchpriority

参考 `sections/slideshow.liquid`：

- `section.index0 == 0` 且首屏可见 → 首图 `eager` + `fetchpriority: high`
- 其余 → `lazy` + `fetchpriority: low`
- 不确定是否首屏 → 保持原版 lazy 行为，避免 LCP 回归

## 第四步：兼容性清单（投流/落地页必查）

改动前 grep 模板与 custom_css，**必须保留**：

- `id`（如 `#left_view`）、业务 class
- 依赖 DOM 结构的 inline script / 第三方脚本
- schema 字段不变（除非用户明确要求）

**不要**删除看似无效但原版存在的属性（如 `block.settings.xxx`），除非用户确认；无效引用可保留或改为等效 fallback，不要 silent 改语义。

## 第五步：优先级定义

| 级别 | 范围 | 典型收益 |
|------|------|----------|
| **P0** | 大背景 Banner、产品主图 | 请求 -50%，流量 -80%+ |
| **P1** | 小角标/贴图（显示 <100px 仍下原图） | 单张 -90% |
| **P2** | 双 video、inline script 抽离 | 视情况 |

- 分析阶段：列出**全部**级别及每级包含的图片点
- 实施阶段：**一次只做一个级别**；该级别完成后汇报，等用户确认再继续

## 第六步：验证（仅阶段 2）

1. **Liquid 校验**：优先用 Shopify MCP `learn_shopify_api(api: liquid)` → `validate_theme`；无 MCP 时说明「未自动校验」，请用户在主题目录手动跑 `shopify theme check` 或 IDE 等价检查
2. **DevTools 对比**（告知用户具体元素）：
   - 选择器、旧版请求数 vs 新版
   - `currentSrc` 中 `width=` 参数
   - 屏幕渲染尺寸 vs 下载尺寸
3. **视觉**：PC + 移动各测；按钮/表单/轮播功能回归

## 输出模板

### 阶段 1：分析（不改代码）

```markdown
## 图片盘点

| 优先级 | 选择器 / 元素 | 当前问题 | 建议方案（sizes/widths 要点） | 预估收益 |
|--------|--------------|----------|------------------------------|----------|
| P0 | ... | 原图直出 | ... | ... |
| P1 | ... | ... | ... | ... |

## 未纳入本次范围
- ...

## 下一步
尚未修改代码。请确认从哪个优先级开始（如「确认，先做 P0」）。
```

### 阶段 2：实施（用户确认后）

```markdown
## 本次优化（P0）
- [具体 DOM/选择器]：旧 → 新

## 预期收益
- 请求 / 流量（估算，注明假设）

## 未改动（待下一优先级）
- P1: ...
- P2: ...

## DevTools 对比
- 元素选择器 + 期望 width= 范围

## 下一步
P0 已完成。是否继续 P1？
```

## 项目约定

- 缩进 2 空格；commit 类型 `perf:`，中文描述
- CSS 选择器优先 `#shopify-section-{{ section.id }}`
- 用 `image_url`/`image_tag`，禁止新增 `img_url`
- 复杂 section 先确认方案再改；投流落地页**尤其谨慎**

## 参考示例

见 [examples.md](examples.md)（solution-img、bf-banner 真实改法）
