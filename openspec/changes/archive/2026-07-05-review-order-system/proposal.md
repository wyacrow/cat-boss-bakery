## Why

OrderSystem 的核心代码（OrderSystem.gd、OrderData.gd、order_slot.gd）已在 `order-system-prototype` change 中完成编写，但经过代码审查发现多处问题：场景文件与脚本节点名不匹配、订单初始化被遗漏、配置值与设计文档不一致等。这些问题会导致运行时 UI 空白、订单生成行为异常，需要在正式集成 InventorySystem 前修复。

## What Changes

- 修复 [order_slot.tscn](scenes/ui/order_slot.tscn) 与 [order_slot.gd](scripts/ui/components/order_slot.gd) 的节点结构不匹配问题
- 修复 [OrderSystem.gd](scripts/systems/OrderSystem.gd) — `_generate_initial_orders()` 未被调用、`generation_interval` 默认值不符合规格
- 修改 [order_slot.gd](scripts/ui/components/order_slot.gd) — 适配 scene 实际结构，去掉冗余检查
- 验证 Click → submit_order 调用链路在场景中的正确性

## Capabilities

### Modified Capabilities

- `order-system`: 修复启动初始化、调整生成间隔默认值、确认信号链路
- `order-slot-ui`: 修复场景节点名与脚本引用的不一致，补全 AnimationPlayer

## Impact

- 修改文件：`scenes/ui/order_slot.tscn`、`scripts/ui/components/order_slot.gd`、`scripts/systems/OrderSystem.gd`
- 不影响 GridBoard、MergeSystem、StaminaSystem、InventorySystem、CatSystem
- 不涉及新架构决策，纯修复性变更
