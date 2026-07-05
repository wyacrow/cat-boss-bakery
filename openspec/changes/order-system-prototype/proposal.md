## Why

OrderSystem 已创建但缺链路闭环：OrderData 内嵌在 OrderSystem 中导致信号传递不便、EventBus 信号传零散字段而非完整数据、OrderSlot UI 交互方式（独立提交按钮）与设计不符、缺少顾客猫概念。需要按讨论确定的设计方案一次性补全。

## What Changes

- 新建 `scripts/data/OrderData.gd` — OrderData 从 OrderSystem 内嵌类抽为独立 RefCounted 类
- 修改 `scripts/systems/OrderSystem.gd` — 使用独立 OrderData、增加顾客猫随机选取、`order_generated` 信号传 OrderData 对象
- 修改 `scripts/core/EventBus.gd` — `order_generated` 信号签名改为 `(order: OrderData)`
- 修改 `scripts/ui/components/order_slot.gd` — 改为点击卡片整提交 + 直接调用 OrderSystem + 挂载 AnimationPlayer（暂不调用）
- 修改 `CLAUDE.md` Rule 5 — 明确 EventBus 用于广播/事件，直接调用用于同步查询/命令（已完成）

## Capabilities

### New Capabilities

- `order-data-class`: OrderData 作为独立数据类，供 EventBus、OrderSystem、OrderSlot 三者共用
- `order-slot-ui`: OrderSlot UI 组件完整交互（卡片点击提交、猫图像、物品图标+数量、金币组、完成动画占位）

### Modified Capabilities

- `order-system`: 增加顾客猫字段、信号改为传 OrderData 对象
- `event-bus`: `order_generated` 信号签名更新

## Impact

- 新增文件：`scripts/data/OrderData.gd`
- 修改文件：`OrderSystem.gd`, `EventBus.gd`, `order_slot.gd`
- 不影响 GridBoard、MergeSystem、StaminaSystem、GameStat
- 暂不涉及 InventorySystem（后续独立 change）
