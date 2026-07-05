## Why

当前项目有操作反馈动画（GridBoard/ItemCellButton 内的 tween：投掷轨迹、交换位移、按下弹起、消耗缩小），但缺乏游戏氛围特效。需要一个独立的特效系统来提供可视化的游戏反馈，例如拖拽合并时的可合成提示光环，以及后续的订单完成金币飘字等。

特效系统与动画系统完全隔离——动画服务于操作反馈（"我做了什么"），特效服务于游戏氛围（"发生了什么值得注意的事"）。

## What Changes

- 新建 `EffectsSystem.gd`，挂载在 GameScene 下作为独立 Node
- 实现**合并提示特效**：拖拽物品悬停在可合成单元格时，目标格显示光环，从小到大出现（ease_out），完全显示后维持呼吸缩放动画，拖离时缩小消失
- 光环使用已有 shader `ring_glow.gdshader` 程序化生成，动画由节点 `scale` + `pivot_offset` 居中缩放驱动
- GridBoard 新增 `get_cell_global_center(pos)` 方法供特效系统查询格子屏幕坐标
- ItemCellButton 在 `_can_drop_data` 中检测可合成状态并触发/隐藏提示
- EventBus 信号 `merge_done` 在 GridBoard 合成成功时被 emit（此前仅定义未发射）

## Capabilities

### New Capabilities

- `effects-system`: 独立的游戏特效播放器，EventBus 驱动 + 直接调用双模式，管理特效节点的创建、动画、回收

### Modified Capabilities

- `grid-board`: 新增 `get_cell_global_center()` 查询接口
- `item-cell-interaction`: `_can_drop_data` 增加合并提示触发逻辑

## Impact

- 新增文件：`scripts/systems/EffectsSystem.gd`
- 修改文件：`GridBoard.gd`（+merge_done emit + get_cell_global_center + set_effects_system）
- 修改文件：`ItemCellButton.gd`（+_effects 引用 + 提示触发逻辑）
- 修改文件：`GameScene.tscn`（+EffectsSystem 节点）
- 修改文件：`GameScene.gd`（+_wire_effects_system 接线）
- 与动画系统零耦合，互不干扰
