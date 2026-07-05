## Context

当前 GameScene.tscn 的 UI 布局存在以下问题：
- **TopHUDBar**：使用硬编码 offset（left=-400, right=-16），宽度为 384px，未适配 1440px 新分辨率。锚点 preset=1（右上角）但 grow_horizontal=0，宽度固定不随父容器缩放。高度也无规范。
- **OrderBar**：anchor_top=0.72 + 硬编码 offset（小数点），位置不精确，占 AreaA_Top 底部约 28% 高度。
- **GridBoard**：anchors_preset=15（全填充）+ offset（-39.5/-129/+39.5/+138），导致棋盘面板溢出 AreaB_Grid 背景区域。
- **BottomPanel**：内部 ButtonContainer 无规范 padding，元素间距依赖隐式布局。

设计分辨率 1440×3120，三区比例 A:B:C = 2:4:1（891:1783:446）。

## Goals / Non-Goals

**Goals:**
- TopHUDBar 宽度 = 父容器宽度 × 0.7，高度 = AreaA_Top 高度 × 0.15，锚点右上角，padding(top=20, right=20, bottom=20)
- OrderBar 锚定 AreaA_Top 底部，高度 = AreaA_Top 高度 × 0.6，全宽无留白
- GridBoard 在 AreaB_Grid 背景内 padding 10px（四边等距）
- BottomPanel 父容器内 padding 20px（四边），内容元素间距 20px
- 使用 anchor 而非硬编码 offset 实现自适应

**Non-Goals:**
- 不改变三区整体比例（A 891 / B 1783 / C 446）
- 不修改脚本逻辑（GameScene.gd、GridBoard.gd）
- 不动 OrderBar 内 OrderSlot 的硬编码 offset

## Decisions

### AreaA_Top 内部布局：TopHUDBar + OrderBar

AreaA_Top（891px）内部三层垂直分区：

```
  0.00 ───────────────────────
       │  TopHUDBar (0.15)    │  anchor: t=0 b=0.15 l=0.3 r=1.0
  0.15 ───────────────────────    offset: t=20 r=-20 b=20
       │  空白区 (0.25)       │    实际尺寸: 988×134
  0.40 ───────────────────────
       │  OrderBar (0.6)       │  anchor: t=0.4 b=1.0 l=0 r=1.0
       │                      │    offset: 全部 0
  1.00 ───────────────────────    实际尺寸: 1440×535
```

### TopHUDBar

- **决策**：`anchor_left=0.3, anchor_right=1.0, anchor_top=0, anchor_bottom=0.15`。`offset_top=20, offset_right=-20, offset_bottom=20, offset_left=0`。
- **宽度**：1440 × 0.7 − 20（右边距）= 988px（方案 A：anchor 计算后减 offset）。
- **高度**：891 × 0.15 − 20(top) − 20(bottom) = 134 − 40 = 94px 实际可用高度。
- **替代方案**：方案 B（宽度精确 70% + 独立右 padding）→ 与 anchor+offset 模型不符，弃用。

### OrderBar

- **决策**：`anchor_top=0.4, anchor_bottom=1.0, anchor_left=0, anchor_right=1.0`，offset 全部清零。
- **理由**：占 AreaA_Top 底部 60%，全宽无 padding。OrderSlot 保持现有硬编码 offset 不变。
- **替代方案**：改用 HBoxContainer → 需要改动 OrderSlot 子节点布局，Non-Goal 排除。

### GridBoard

- **决策**：`anchors_preset=15`（全填充），`offset_left=10, offset_top=10, offset_right=-10, offset_bottom=-10`。
- **理由**：anchor + offset 实现四边 10px padding，这是 Godot 中最直接的方式。
- GridContainer 保持 `size_flags_horizontal=4, size_flags_vertical=4`（居中）。

### BottomPanel

- **决策**：BottomPanel 使用 anchor 全填充 + `offset_left=20, offset_top=20, offset_right=-20, offset_bottom=-20`。ButtonContainer `theme_override_constants/separation=20`。

## Risks / Trade-offs

- **TopHUDBar 内容溢出**：宽度 988px，HUD 内容（160+120+48+32=360px）远小于可用宽度，无溢出风险。
- **OrderSlot 硬编码适配**：OrderBar 从 anchor 0.72→0.4 扩大后，OrderSlot 的 offset（left=16,152,288 / width=120）仍能正确排列，不需修改。
- **GridBoard 不居中**：保持 `size_flags=4` 确保 GridContainer 居中。
