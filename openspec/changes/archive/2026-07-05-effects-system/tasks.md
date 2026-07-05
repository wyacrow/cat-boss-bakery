## 1. GridBoard 接口扩展

- [x] 1.1 合成成功后 emit `EventBus.merge_done(from_pos, to_pos, result_item)`
- [x] 1.2 新增 `get_cell_global_center(pos: Vector2i) -> Vector2` 查询格子屏幕中心坐标
- [x] 1.3 新增 `set_effects_system(effects: EffectsSystem)` 分发给所有 cell

## 2. EffectsSystem 核心

- [x] 2.1 创建 `scripts/systems/EffectsSystem.gd`，extends Node，class_name EffectsSystem
- [x] 2.2 实现 `setup(grid_board)` 注入棋盘引用 + 连接 EventBus 信号
- [x] 2.3 实现合并提示状态机（appearing → breathing → disappearing → 清理）
- [x] 2.4 实现 `show_merge_hint(at_pos, target_item)` — 在指定格创建光环特效
- [x] 2.5 实现 `hide_any_hint()` — 隐藏当前活跃的合并提示

## 3. 合并提示光环特效

- [x] 3.1 使用 `ring_glow.gdshader` + ShaderMaterial 程序化生成光环
- [x] 3.2 出现动画：`scale` 0→2.0 + `base_color.a` 驱动透明度 0→0.3，0.18s，ease_out 先快后慢
- [x] 3.3 呼吸动画：`scale` 2.0↔2.1，sinusoidal 循环
- [x] 3.4 消失动画：`scale` 当前→0 + 淡出，0.12s，ease_in 先慢后快
- [x] 3.5 不同物品类型配色：面包=暖橙、甜点=粉红、饮品=天蓝
- [x] 3.6 使用 `pivot_offset` 居中 + 节点 `scale` 动画（替代 shader `scale_size` 参数，方向直观）

## 4. ItemCellButton 交互集成

- [x] 4.1 新增 `_effects: EffectsSystem` 引用 + `set_effects_system()` 注入方法
- [x] 4.2 `_can_drop_data` 中检测 `can_merge_with` + `!is_max_level` 触发提示
- [x] 4.3 拖回原位（`from_pos == cell_position`）时不显示提示
- [x] 4.4 `NOTIFICATION_DRAG_END` 时清除提示

## 5. 场景与连线

- [x] 5.1 `GameScene.tscn` 添加 EffectsSystem 节点（GameScene 子节点）
- [x] 5.2 `GameScene.gd` 实现 `_wire_effects_system()` 注入 GridBoard 引用到 EffectsSystem 和所有 cell

## 6. 稳定性

- [x] 6.1 快速拖拽时 tween 正确清理（_kill_hint 先 kill 所有 tween 再 queue_free 节点）
- [x] 6.2 消失中拖回同一格时取消消失动画重新出现
- [x] 6.3 不同格子间快速切换时立即清理旧提示创建新提示
