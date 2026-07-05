## Why

当前 UI 布局存在多个间距和对齐不一致问题：TopHUDBar 使用硬编码 offset 定位且宽度未适配新分辨率 1440×3120；GridBoard 的 offset 超出父容器导致视觉溢出；BottomPanel 无规范 padding。需要统一调整各组件的锚点、padding 和间距，使布局整洁、适配新分辨率且有规整的呼吸空间。

## What Changes

- **TopHUDBar**：宽度改为父容器的 0.7 倍，锚点固定右上角，上边距和右边距各 20px
- **GridBoard**：棋盘背景内上下左右各 padding 10px，GridBoard 使用 anchor 自适应填充
- **BottomPanel**：父容器内上下左右各 padding 20px，内容元素间距 20px

## Capabilities

### New Capabilities

- `layout-rebalance`: UI 三区（A/B/C）的锚点、padding、间距统一规范化

### Modified Capabilities

<!-- 纯布局调整，无 spec 级别需求变更 -->

## Impact

- `scenes/GameScene.tscn` — TopHUDBar、GridBoard、BottomPanel 及其子节点的 anchor/offset/padding 属性
- `CLAUDE.md` — 更新布局规范说明（如有需要）
