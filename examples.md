# 优化示例

## 示例 1：solution-img（分栏 + 全宽）

### CSS 事实

- PC padding：78px × 2；容器 max 1360px → 内容区 max 1204px
- 移动 padding：12px × 2（`--card-section-padding-mobile`）
- 左右分栏 gap：30px → 单列 max ≈ 587px
- 断点：699px

### Liquid assigns

```liquid
assign mobile_sizes = 'calc(100vw - 24px)'
assign top_desktop_sizes = '(min-width: 700px) min(1204px, calc(100vw - 156px))'
assign split_desktop_sizes = '(min-width: 700px) calc((min(1204px, 100vw - 156px) - 30px) / 2)'
assign top_desktop_widths = '600,800,1000,1200,1600,2000,2400'
assign split_desktop_widths = '320,480,640,800,1000,1200'
```

### DevTools 对比点

| 元素 | 旧版 | 新版 |
|------|------|------|
| `.slideshow__image` N/A | 每 slot 2 张原图 | 每 slot 1 张 |
| 顶部 picture img | — | PC `width≈1200`，移动 `width≈750` |
| 分栏 picture img | — | PC `width≈600`，移动 `width≈750` |

---

## 示例 2：bf-banner P0

### P0 范围

1. `.slideshow__image.box` — 背景 Banner
2. `.bf-ct-swiper-image` — 产品轮播主图

**未改**：`.discount_tag_wrapper img`、`.cover_image_right_wrapper img`

### 背景 Banner

```liquid
assign banner_sizes = '100vw'
assign banner_desktop_widths = '800,1000,1200,1600,1920,2400'
assign banner_mobile_width_list = '390,480,640,750,960,1200' | split: ','
```

- `<picture>` 断点：`749px`（对齐 `hideMobile`/`hideDesktop`）
- `picture { display: contents }` 保持 absolute 布局

### 产品图

```liquid
assign product_card_sizes = '(min-width: 768px) 150px, 180px'
assign product_card_widths = '150,180,300,360'
# image_url: width: 360
```

CSS：`≥768px` → 150×150；`≤749px` → 180×180。750–767px 渲染 155px，sizes fallback 180px，可接受。

### DevTools 对比点

| 选择器 | 期望 currentSrc |
|--------|-----------------|
| `.slideshow__image.box` | PC：`width=1200–2400`；移动：`width=750–960` |
| `.bf-ct-swiper-image` × N | `width=150/300`（PC）或 `180/360`（移动） |

### 已知权衡

- Banner `image_url` 上限 2400：2x 超大屏可能比旧版 3840 原图略软；需更清晰时提到 3840
- `sales-new` 未配 `mobile_image` 时，移动仍用 PC 图 srcset，体积仍优于原图

---

## 反例：不要这样做

```liquid
{# 错：双 img + CSS 隐藏 #}
<div class="hideMobile"><img src="{{ pc | image_url }}"></div>
<div class="hideDesktop"><img src="{{ mob | image_url }}"></div>

{# 错：sizes 未读 CSS #}
sizes: '100vw'  {# 实际有 78px padding #}
sizes: 'calc(50vw - 69px)'  {# 未算 max-width 和 gap #}

{# 错：改动无关代码 #}
{# 删除 block.settings.alignment、重构 schema、改 Klaviyo script #}
```
