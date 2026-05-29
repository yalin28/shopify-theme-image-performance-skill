---
name: shopify-theme-image-performance
description: >-
  Never edit files on the first response. The first response must be
  read-only analysis only. Optimizes image loading in Shopify theme sections
  and snippets without changing visual layout. Audits CSS to derive responsive
  sizes/widths, migrates legacy img_url to image_url/image_tag, chooses between
  <picture> and single image_tag, and tunes loading/fetchpriority. Always
  analyzes and lists P0-Pn priorities first; only implements after the user
  explicitly confirms one priority.
---

# Shopify 主题图片性能优化

## 最高优先级门禁（必须遵守）

**Never edit files on the first response. The first response must be read-only analysis only.**

首次响应用户的图片优化请求时，**禁止修改任何文件**。即使用户说「优化」「全部优化」「直接优化这个文件」，第一轮也只能读代码、分析问题、输出 P0–Pn 清单，并等待用户明确确认某一个优先级后才能实施。

**默认两阶段，禁止跳步：**

| 阶段 | 触发 | 允许 | 禁止 |
|------|------|------|------|
| **阶段 1：分析** | 用户提出优化请求 | 读代码/CSS、盘点图片、输出 P0–Pn 清单与方案 | **修改任何文件** |
| **阶段 2：实施** | 用户**明确确认**要做某一优先级 | 仅实施用户确认的那一个 Px | 一次性改多个优先级；未确认就改代码 |

**硬规则：**

1. **第一轮永远只读** — 不管用户措辞多像执行指令，首次响应都不能编辑文件
2. **先分析、后修改** — 首次响应只做优先级盘点，不主动改文件
3. **用户确认后才改** — 用户说「开始 P0」「确认 P0」等明确指令后，才进入阶段 2
4. **逐级实施** — 必须 P0 → P1 → P2 顺序；当前级别验证完成并获用户确认后，才进入下一级
5. **用户只确认 P0** — 只做 P0，P1/P2 留在「待做清单」，不得顺带修改
6. **用户要求「全部优化」** — 仍按 P0 先做，完成后汇报并等待确认再做 P1（不可一轮全改）

**阶段 1 结束语模板：**

> 以上为分析结果，尚未修改代码。请确认从哪个优先级开始（如「确认，先做 P0」）。

## 何时触发本 skill

满足以下任一情形时使用：

- 用户要求"优化 section/snippet 的图片加载、首屏速度、LCP"
- 出现 `img_url` / `img_url: 'small'` / `replace: '_small'` 等遗留写法需要迁移到 `image_url` / `image_tag`
- 出现 PC/移动两套 `<img>` 配合 `hideMobile` / `hideDesktop` 等 CSS 隐藏的写法
- 需要为现有 `<img>` 补 `srcset` / `sizes` / `widths`，或决定 `<picture>` vs `image_tag`
- 投流 / 落地页 section 图片体积、请求数明显偏大

不适用：纯 JS / video / schema / 第三方脚本性能问题（见"超出本 skill 范围"）。

## 目标

在**不改变视觉布局**的前提下，减少图片 HTTP 请求数与传输体积。改动必须 surgical：只动图片相关代码，不 refactor 相邻逻辑。

## 全局约定

- **断点统一以项目 CSS 实际值为准**。本 skill 所有示例使用 Shopify Dawn 约定的 **749 / 750px**（移动 ≤749px，PC ≥750px）。实际改写时把示例里的 749/750 替换成项目 CSS 中真实的隐藏断点与媒体查询。
- CSS 选择器优先 `#shopify-section-{{ section.id }}` 范围化，避免污染全局。
- 用 `image_url` / `image_tag`，**禁止新增 `img_url`**（已废弃）。
- **`widths` 统一为逗号分隔字符串**（对齐 Shopify 官方 `image_tag: widths: '200, 300, 400'` 约定）。`image_tag` 直接传字符串；手写 `<source srcset>` 需要遍历时显式 `| split: ','` 转数组——单一来源，不混用两种形态。
- 投流落地页改动尤其谨慎，**必须保留** id、业务 class、依赖 DOM 的 inline script / 第三方脚本钩子。

## 执行流程

```
阶段 1 — 分析（只读）
  STOP: 不要编辑、创建、删除、格式化任何文件；不要调用写入型工具；不要运行会改文件的命令
  STOP: 即使用户说「优化」「全部优化」「直接改」，首次响应也必须停在分析报告
  1. 读 section + 关联 CSS/assets + template 用法
  2. 盘点所有图片点 → 识别反模式
  3. 从 CSS 推导各图片点的 sizes/widths 方案（写在分析里，不写进文件）
  4. 按 P0/P1/P2 排序，输出完整清单
  5. 等待用户确认

阶段 2 — 实施（用户确认后）
  1. 只改用户确认的那一个 Px
  2. 实施最小 diff
  3. 校验（见"第六步：验证"）
  4. 输出：改了什么、未改什么、DevTools 对比点、预估收益
  5. 询问是否继续下一优先级
```

## 第一步：识别反模式（按危害排序）

> **反模式（anti-pattern）**：看似合理、实际有害的常见写法。语法没错、能跑通，但会带来性能、维护或回归风险，属于"看到就该改"的固定套路。

| 反模式 | 问题 |
|--------|------|
| PC/移动双 `<img>` + `hideMobile`/`hideDesktop` | 隐藏图仍会下载 |
| `img_url` 或 `img_url: 'small'` / `replace: '_small', ''` | 已废弃，实际下原图 |
| `image_url` 无 `width` / 裸 `<img src=` | 原图直出 |
| `sizes="auto"` 或 `100vw` 未扣 padding/max-width | CDN 尺寸与 CSS 不符 |
| 无 `loading` / 首屏以下仍 eager | 浪费首屏带宽 |

## 第二步：从 CSS 推导 CDN 规则（必做）

**禁止**凭猜测写 `sizes`。必须对照：

- 元素实际 `width`/`height`/`max-width`/`padding`/`gap`
- 断点（记录 exact px，如 749/750）
- 容器 `max-width`（如 `aosu-product-card` 1360px）
- 2x 视网膜：`widths` 上限 ≈ 渲染宽 × 2

常用公式：

```liquid
assign mobile_sizes = 'calc(100vw - [mobile_padding_total]px)'
assign desktop_sizes = '(min-width: 750px) min([content_max]px, calc(100vw - [pc_padding_total]px))'
assign split_sizes = '(min-width: 750px) calc((min([content_max]px, 100vw - [padding]px) - [gap]px) / 2)'
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

### 防御：image 为 blank

Liquid 的 `image_url` / `image_tag` 在 image 为 `blank` 时会渲染异常或输出空 src，投流落地页尤其危险。**所有图片渲染都必须先判 blank**：

```liquid
{%- if image != blank -%}
  {{ image | image_url: width: max_width | image_tag: ... }}
{%- else -%}
  {%- comment -%} 占位 / 跳过，按业务决定 {%- endcomment -%}
{%- endif -%}
```

`<picture>` 内 `<source>` 也要包 `{% if mobile_image != blank %}`，否则会输出 `srcset=""` 触发浏览器告警。

### A. PC/移动不同图 → `<picture>`

```liquid
{%- assign desktop_widths = '800,1000,1200,1600,2000,2400' -%}
{%- assign mobile_widths = '390,480,640,750,960,1200' -%}
{%- assign mobile_widths_arr = mobile_widths | split: ',' -%}
{%- assign desktop_sizes = '(min-width: 750px) min(1360px, calc(100vw - 156px))' -%}
{%- assign mobile_sizes = 'calc(100vw - 24px)' -%}
{%- assign image_loading = 'eager' -%}
{%- assign image_fetchpriority = 'high' -%}

{%- if desktop_image != blank -%}
<picture>
  {%- if mobile_image != blank -%}
    <source
      media="(max-width: 749px)"
      srcset="{% for w in mobile_widths_arr %}{{ mobile_image | image_url: width: w }} {{ w }}w{% unless forloop.last %}, {% endunless %}{% endfor %}"
      sizes="{{ mobile_sizes }}"
    >
  {%- endif -%}
  {{-
    desktop_image
    | image_url: width: 2400
    | image_tag:
      class: 'banner__img',
      loading: image_loading,
      fetchpriority: image_fetchpriority,
      sizes: desktop_sizes,
      widths: desktop_widths,
      alt: desktop_image.alt
  -}}
</picture>
{%- endif -%}
```

- `<source>` 的 `media` 必须与 CSS 隐藏断点**一致**（默认对齐 749px，按项目实际值调整）
- `<img>` 的 `sizes` 给 PC；`<source>` 的 `sizes` 给移动
- 移动图未配时：不输出 `<source>`，自动 fallback 到 `<img>`
- `desktop_widths` 直接传字符串给 `image_tag`；`mobile_widths` 需先 `| split: ','` 再供 `<source>` 循环
- 布局：**当父元素用 `position: relative` / `flex` / `grid` 直接对子 `<img>` 做定位或对齐时**，需要加 `#shopify-section-{{ section.id }} ... picture { display: contents; }`。否则 `<picture>` 作为 inline 元素会插入到父子之间，打断原有 absolute 定位、flex 子项布局或 grid 占位（不需要时不要加，徒增样式覆盖面）

### B. 单图多尺寸 → `image_tag` + `widths`

`assign` 出来的字符串变量可以直接传入 `image_tag`，与硬编码字符串等价——首选 `assign`，便于复用与从 CSS 推导：

```liquid
{%- assign card_sizes = '(min-width: 750px) 150px, 180px' -%}
{%- assign card_widths = '150,180,300,360' -%}

{%- if image != blank -%}
{{-
  image
  | image_url: width: 360
  | image_tag:
    class: 'card__img',
    loading: 'lazy',
    fetchpriority: 'low',
    sizes: card_sizes,
    widths: card_widths,
    alt: image.alt
-}}
{%- endif -%}
```

- `image_url: width:` 设上限（≈ 渲染宽 × 2，对齐 `widths` 最大值）
- `sizes` / `widths` 变量名无要求，传字符串即可；`image_tag` 内部会自行 split

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
- 所有图片渲染外层加 `{%- if image != blank -%}` 保护

**不要**删除看似无效但原版存在的属性（如 `block.settings.xxx`），除非用户确认；无效引用可保留或改为等效 fallback，不要 silent 改语义。

## 第五步：优先级定义

本 skill 仅覆盖**图片相关**优化。非图片项一律标注为"超出本 skill 范围"，不纳入 P0–P2。

| 级别 | 范围（仅图片） | 判定依据 | 典型收益 |
|------|---------------|---------|---------|
| **P0** | 影响 LCP / 首屏的图片：全宽 Banner、Hero、首屏产品主图、首屏双 `<img>` 隐藏 | 出现在首屏视口、原图直出或被双 img 重复下载 | 请求 -50%，流量 -80%+ |
| **P1** | 首屏外但仍下原图的图片：列表/推荐位主图、重复出现的卡片图 | 首屏外但走 `<img src=` 原图或缺 `srcset` | 单张 -70%~90%、批量见效 |
| **P2** | 装饰/低收益图片：固定小尺寸（<100px）角标、icon-like、源文件已很小 | 仅作小幅压缩、不影响 LCP | 视情况；常 <10% 收益 |

**取舍提示：**

- 若 P2 候选预估收益 <5% 或源已 ≤ 渲染宽 × 2，**可不做**；直接在分析里标注为"已最优"。
- 双 `<video>`、inline script 抽离、CSS / JS 拆包、字体优化等**非图片性能项**：**超出本 skill 范围**，在阶段 1 报告里单列"建议另行处理"，不要顺带改。

- 分析阶段：列出**全部**级别及每级包含的图片点，并把超出范围的项独立列出
- 实施阶段：**一次只做一个级别**；该级别完成后汇报，等用户确认再继续

## 第六步：验证（仅阶段 2）

按以下顺序，**任一可用即可**，不要因 MCP 不可用而放弃校验：

1. **Liquid 语法 / 主题校验**
   - **优先**：Shopify MCP — `learn_shopify_api(api: liquid)` → `validate_theme`
   - **降级 1（推荐本地）**：在主题根目录执行
     ```bash
     shopify theme check                 # 全量
     shopify theme check sections/xxx.liquid  # 单文件
     ```
     未安装 CLI：`brew install shopify-cli`（macOS）/ `npm i -g @shopify/cli @shopify/theme`。
   - **降级 2**：IDE 自带 Liquid / Theme Check 插件（如 Shopify Liquid VSCode 扩展）保存时自动校验。
   - **降级 3（最低）**：人工 diff 检查——`{% %}` / `{%- -%}` / `{{ }}` 配对、`endif` / `endfor` / `endpicture` 闭合、引号未跨行。
   - 如以上均不可用，**必须**在交付摘要中显式写明"未执行 Liquid 自动校验，已做人工配对检查"。

2. **DevTools 网络对比**（告知用户具体元素）
   - 选择器、旧版请求数 vs 新版
   - `currentSrc` 中 `width=` 参数
   - 屏幕渲染尺寸 vs 下载尺寸（DPR 已考虑）

3. **视觉 & 功能**：PC + 移动各测；按钮 / 表单 / 轮播 / hover 状态回归。

## 输出模板

### 阶段 1：分析（不改代码）

```markdown
## 图片盘点

| 优先级 | 选择器 / 元素 | 当前问题 | 建议方案（sizes/widths 要点） | 预估收益 |
|--------|--------------|----------|------------------------------|----------|
| P0 | ... | 原图直出 | ... | ... |
| P1 | ... | ... | ... | ... |
| P2 | ... | ... | ... | ... |

## 超出本 skill 范围（建议另行处理）
- 双 video / inline script 抽离 / 第三方脚本 / ...

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

## 校验
- 使用 [MCP validate_theme | shopify theme check | 人工 diff] —— 通过 / 失败原因

## DevTools 对比
- 元素选择器 + 期望 width= 范围

## 下一步
P0 已完成。是否继续 P1？
```

## 内联示例

### 示例 1：分栏 + 全宽（solution-img 类型）

**CSS 事实：**

- PC padding：78px × 2；容器 max 1360px → 内容区 max 1204px
- 移动 padding：12px × 2
- 左右分栏 gap：30px → 单列 max ≈ 587px
- 断点：749/750px（按项目实际值替换）

**Liquid assigns：**

```liquid
{%- assign mobile_sizes = 'calc(100vw - 24px)' -%}
{%- assign top_desktop_sizes = '(min-width: 750px) min(1204px, calc(100vw - 156px))' -%}
{%- assign split_desktop_sizes = '(min-width: 750px) calc((min(1204px, 100vw - 156px) - 30px) / 2)' -%}
{%- assign top_desktop_widths = '600,800,1000,1200,1600,2000,2400' -%}
{%- assign split_desktop_widths = '320,480,640,800,1000,1200' -%}
```

**衔接示例（顶部全宽图 → 模式 B）：**

```liquid
{%- if section.settings.top_image != blank -%}
{{-
  section.settings.top_image
  | image_url: width: 2400
  | image_tag:
    class: 'solution-img__top',
    loading: 'eager',
    fetchpriority: 'high',
    sizes: top_desktop_sizes,
    widths: top_desktop_widths,
    alt: section.settings.top_image.alt
-}}
{%- endif -%}
```

分栏图把 `top_desktop_sizes` / `top_desktop_widths` 换成 `split_desktop_sizes` / `split_desktop_widths` 即可。

**DevTools 对比点：**

| 元素 | 旧版 | 新版 |
|------|------|------|
| 顶部图 | 原图直出（无 `width=` 参数） | `width≈1200`（PC）/ `width≈750`（移动） |
| 分栏图 | 原图直出（无 `width=` 参数） | `width≈600`（PC）/ `width≈750`（移动） |

### 示例 2：背景 Banner + 产品轮播（bf-banner 类型）

**P0 范围：** `.slideshow__image.box`（背景 Banner）、`.bf-ct-swiper-image`（产品轮播主图）。
未改：`.discount_tag_wrapper img`、`.cover_image_right_wrapper img`（P1/P2）。

**背景 Banner（PC/移动不同图 → 模式 A）：**

```liquid
{%- assign banner_sizes = '100vw' -%}
{%- assign banner_desktop_widths = '800,1000,1200,1600,1920,2400' -%}
{%- assign banner_mobile_widths = '390,480,640,750,960,1200' -%}
{%- assign banner_mobile_widths_arr = banner_mobile_widths | split: ',' -%}
```

- `<picture>` 断点：`749px`（对齐 `hideMobile` / `hideDesktop`）
- `.slideshow__image.box` 父级用 `position: absolute` 拉满，因此需要 `#shopify-section-{{ section.id }} picture { display: contents; }`，让 picture 在布局上"透明"，子 img 仍受父级 absolute 控制
- 已知权衡：`image_url` 上限 2400，2x 超大屏可能比旧版 3840 原图略软；如需更清晰提升到 3840

**产品图：**

```liquid
{%- assign product_card_sizes = '(min-width: 750px) 150px, 180px' -%}
{%- assign product_card_widths = '150,180,300,360' -%}

{%- if product.featured_image != blank -%}
{{-
  product.featured_image
  | image_url: width: 360
  | image_tag:
    class: 'bf-ct-swiper-image',
    loading: 'lazy',
    fetchpriority: 'low',
    sizes: product_card_sizes,
    widths: product_card_widths,
    alt: product.title
-}}
{%- endif -%}
```

CSS：`≥750px` → 150×150；`≤749px` → 180×180。

### 示例 3：P1 — 首屏外卡片图（接 bf-banner P0 之后）

P0 处理完 Banner 与首屏轮播主图后，P1 通常是**首屏外的卡片/推荐位主图**——例如下文 `.cover_image_right_wrapper img` 这种「单图多尺寸、不需要 PC/移动分图」的场景，套**模式 B**：

```liquid
{%- assign cover_sizes = '(min-width: 750px) calc((min(1360px, 100vw - 156px) - 30px) / 2), calc(100vw - 24px)' -%}
{%- assign cover_widths = '320,480,640,800,1000,1200,1600' -%}

{%- if block.settings.cover_image != blank -%}
{{-
  block.settings.cover_image
  | image_url: width: 1600
  | image_tag:
    class: 'cover_image_right',
    loading: 'lazy',
    fetchpriority: 'low',
    sizes: cover_sizes,
    widths: cover_widths,
    alt: block.settings.cover_image.alt
-}}
{%- endif -%}
```

`.discount_tag_wrapper img` 这类**固定 <100px 的小角标**则归 P2，按"B 的简化版"——只补 `image_url: width:` 与 `loading: 'lazy'`，不需要 srcset：

```liquid
{%- if block.settings.discount_tag != blank -%}
<img
  src="{{ block.settings.discount_tag | image_url: width: 120 }}"
  width="60" height="60"
  loading="lazy" fetchpriority="low"
  alt="{{ block.settings.discount_tag.alt }}"
>
{%- endif -%}
```

### 反例：不要这样做

```liquid
{# 错：双 img + CSS 隐藏，隐藏图仍下载 #}
<div class="hideMobile"><img src="{{ pc | image_url }}"></div>
<div class="hideDesktop"><img src="{{ mob | image_url }}"></div>

{# 错：sizes 未读 CSS #}
sizes: '100vw'             {# 实际有 78px padding #}
sizes: 'calc(50vw - 69px)' {# 未算 max-width 和 gap #}

{# 错：image 为 blank 直接渲染，输出空 src 触发浏览器告警 #}
{{ image | image_url: width: 1200 | image_tag: ... }}

{# 错：改动无关代码 #}
{# 删除 block.settings.alignment、重构 schema、改 Klaviyo script #}
```
