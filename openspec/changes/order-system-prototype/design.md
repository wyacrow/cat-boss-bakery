## Context

在完成 OrderSystem.gd（订单生成+提交）和 order_slot.gd（UI 组件雏形）后，与用户讨论确定了以下关键设计决策。此 change 将这些决策落地为代码。

## Goals / Non-Goals

**Goals:**
- 将 OrderData 从 OrderSystem 内嵌类抽为 `scripts/data/OrderData.gd` 独立类
- OrderSystem 增加顾客猫字段，`_generate_order()` 随机选取猫类型（V1 统一使用一个图像占位）
- EventBus `order_generated` 信号改为传递 OrderData 对象
- OrderSlot UI 重构：点卡片本身提交、直接调用 `OrderSystem.submit_order()`、挂载 AnimationPlayer
- 信号仅用于广播（`order_generated` → UI 刷新，`order_completed` → GameStat 加金币）

**Non-Goals:**
- 不实现 InventorySystem（后续独立 change）
- 不实现订单完成的动画播放逻辑（仅挂载 AnimationPlayer 占位）
- 不修改金币系统的信号签名
- 不修改棋盘/合成相关代码

## Decisions

### 1. OrderData 独立为 `scripts/data/OrderData.gd`

**决策**: RefCounted 类，包含 `id`, `requirements`, `base_reward`, `customer_cat`

**理由**:
- EventBus 信号需要 OrderData 类型，但 OrderData 内嵌在 OrderSystem 中时外部无法引用
- Item 已是独立数据类，OrderData 遵循相同模式
- 解耦后 EventBus、OrderSystem、OrderSlot 三者都能直接引用

### 2. 信号传递 OrderData 对象

**决策**: `order_generated(order: OrderData)` — 传递完整对象，不拆字段

**理由**:
- UI 渲染需要所有字段（id、需求、奖励、猫类型），拆字段会导致信号臃肿
- 未来新增字段时只改 OrderData 即可，信号签名不变

**备选方案**: 信号传多个零散参数 → 与用户讨论后否决

### 3. 顾客猫随机选取，V1 统一图像

**决策**: `_pick_customer_cat()` 从 3 种猫中随机选取（tabby/black/white），但 V1 统一使用一个占位图像

**理由**:
- 顾客猫与玩家的 3 只猫（面包/咖啡/工程）是不同概念，增加视觉多样性
- V1 没有多张猫图资源，先统一占位，后续替换

### 4. 提交 = 点击卡片本身

**决策**: OrderSlot 整体接收 gui_input，不再有独立 RewardBtn 子按钮

**理由**: 用户明确要求"提交按钮是卡片本身"，减少交互层级

### 5. submit 直接调用 OrderSystem

**决策**: OrderSlot 持有 OrderSystem 引用，点击时直接调 `order_system.submit_order(order_id)`

**理由**:
- 同步操作需要返回值（成功/失败），EventBus 信号是 fire-and-forget
- 符合 CLAUDE.md Rule 5 更新后的规范：同步命令用直接调用
- 调用成功后 OrderSystem 内部 emit `order_completed` 事件 → GameStat 响应

**备选方案**: 用 `order_submit_request` + `order_submit_result` 两个信号配对 → 过度工程化

### 6. 订单完成动画 — 挂载不调用

**决策**: OrderSlot 挂载 AnimationPlayer 节点，但 `submit_order` 成功后暂不触发动画

**理由**: 用户要求"可以先挂着动画组件不调用"，动画具体效果待后续设计

## Risks / Trade-offs

- **[OrderSlot 持有 OrderSystem 引用]** 打破了 UI 与系统的严格解耦 → 但 CLAUDE.md 已更新为允许 UI 直接调用系统方法
- **[OrderData 独立类]** 增加文件数，但 Item 已有先例，一致性好

## Open Questions

（无）
