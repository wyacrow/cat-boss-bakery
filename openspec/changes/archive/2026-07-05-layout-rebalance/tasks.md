## 1. TopHUDBar 锚点、宽度和高度调整

- [x] 1.1 修改 TopHUDBar 的 anchor：`anchor_left=0.3, anchor_right=1.0, anchor_top=0, anchor_bottom=0.15`
- [x] 1.2 设置 offset：`offset_left=0, offset_top=20, offset_right=-20, offset_bottom=20`
- [x] 1.3 确认 `grow_horizontal=2, grow_vertical=2`

## 2. OrderBar 锚定底部

- [x] 2.1 修改 OrderBar 的 anchor：`anchor_top=0.4, anchor_bottom=1.0, anchor_left=0, anchor_right=1.0`
- [x] 2.2 清零 OrderBar 所有 offset（`offset_left=0, offset_top=0, offset_right=0, offset_bottom=0`）
- [x] 2.3 确认 OrderSlot 硬编码 offset 在 OrderBar 尺寸变化后仍排列正确

## 3. GridBoard padding 调整

- [x] 3.1 设置 GridBoard offset：`offset_left=10, offset_top=10, offset_right=-10, offset_bottom=-10`
- [x] 3.2 确认 GridContainer 的 `size_flags_horizontal=4, size_flags_vertical=4` 保持居中

## 4. BottomPanel 布局调整

- [x] 4.1 设置 BottomPanel offset：`offset_left=20, offset_top=20, offset_right=-20, offset_bottom=-20`
- [x] 4.2 设置 ButtonContainer `theme_override_constants/separation=20`

## 5. 验证

- [x] 5.1 确认 TopHUDBar 118×94px（实际可用空间），锚定右上角
- [x] 5.2 确认 OrderBar 1440×535，填充 AreaA_Top 底部 60%
- [x] 5.3 确认 GridBoard 在棋盘背景内四边各留 10px
- [x] 5.4 确认 BottomPanel 四边 20px padding + 内容间距 20px
