## 1. OrderData 独立数据类

- [x] 1.1 创建 `scripts/data/OrderData.gd` — RefCounted 类，字段：`id: String`, `requirements: Dictionary`, `base_reward: int`, `customer_cat: String`

## 2. EventBus 信号更新

- [x] 2.1 修改 `scripts/core/EventBus.gd` — `order_generated` 信号签名从 `(order_id, requirements)` 改为 `(order: OrderData)`

## 3. OrderSystem 更新

- [x] 3.1 删除内嵌 `class OrderData`，改为使用独立 `OrderData` 类
- [x] 3.2 `_generate_order()` 增加 `_pick_customer_cat()` 方法，从 3 种猫中随机选取
- [x] 3.3 `order_generated` 信号 emit 改为传递 OrderData 对象：`EventBus.order_generated.emit(order)`
- [x] 3.4 `_generate_initial_orders()` 和 `_on_generation_tick()` 适配新 emit 方式

## 4. OrderSlot UI 组件重构

- [x] 4.1 修改 `scripts/ui/components/order_slot.gd` — `set_order()` 改为接收 `OrderData` 对象
- [x] 4.2 移除独立 RewardBtn 交互，改为整体 `gui_input` 处理点击
- [x] 4.3 点击卡片 → 直接调用 `order_system.submit_order(order_id)`，移除 `order_submitted` 信号
- [x] 4.4 增加 OrderSystem 引用（`var order_system: Node`）+ `set_order_system()` 注入方法
- [x] 4.5 增加 `customer_cat` 显示字段 + `set_cat_texture()` 占位
- [x] 4.6 增加 `AnimationPlayer` 子节点引用（`@onready var _anim_player: AnimationPlayer`），暂不调用
- [x] 4.7 增加多个需求物品的显示支持（当前仅显示第一个需求）

## 5. 验证

- [ ] 5.1 启动项目，确认 EventBus 无新错误、OrderSystem 初始化输出 3 个订单
- [ ] 5.2 确认 `order_generated` 信号携带完整 OrderData 对象
- [ ] 5.3 确认 OrderSlot 点击卡片 → `submit_order` 调用链路（暂无 Inventory 时返回 false 为预期行为）
