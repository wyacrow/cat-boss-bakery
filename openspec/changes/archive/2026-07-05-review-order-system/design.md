## Context

`order-system-prototype` change 已完成 OrderData、OrderSystem、OrderSlot 的代码编写和 EventBus 信号更新，但尚未进行验证（tasks 5.1-5.3 未完成）。本轮审查发现 4 类问题需修复后才能进入验证阶段。

## Goals / Non-Goals

**Goals:**
- 修复 scene 节点名与脚本 `_cache_children()` 的引用不匹配
- 修复 `_generate_initial_orders()` 遗漏调用
- 将 `generation_interval` 默认值修正为设计文档规定的 60s
- 补全 scene 中缺少的 AnimationPlayer 节点

**Non-Goals:**
- 不修改 OrderData、EventBus 信号签名（已正确）
- 不修改订单生成/提交的核心逻辑
- 不新增 InventorySystem 集成
- 不新增订单动画逻辑

## Decisions

### 1. TSCN 节点结构整改

**问题**: [order_slot.gd](scripts/ui/components/order_slot.gd) `_cache_children()` 查找以下节点：
- `CatIcon` → `TextureRect`
- `RequirementsContainer` → `Control`（动态创建需求行）
- `RewardGroup` → 容器，内含 `GoldIcon` + `RewardLabel`
- `AnimationPlayer`

但 [order_slot.tscn](scenes/ui/order_slot.tscn) 实际结构为：
- `CatIcon` ✅ 存在
- `ItemContainer` ❌ 脚本需要 `RequirementsContainer`
- `RewardBtn` ❌ 脚本需要 `RewardGroup`（且 RewardBtn 内含 `RewardContainer` 实例，无独立的 GoldIcon/RewardLabel）
- 无 AnimationPlayer ❌

**决策**: 将 scene 的 `ItemContainer` 重命名为 `RequirementsContainer`，将 `RewardBtn` 重构为 `RewardGroup`（内含 `GoldIcon` + `RewardLabel`），新增 `AnimationPlayer` 节点。

**理由**: 脚本逻辑是正确的，scene 只需对齐命名即可。RewardBtn 中的 RewardContainer 实例可移除以简化结构。

### 2. 初始化订单生成

**问题**: `_generate_initial_orders()`（第 144 行）定义了但 `_ready()` 中未调用。所有 3 个槽位初始为空，玩家需等待 `generation_interval` 秒才能看到第一个订单。

**决策**: 在 `_ready()` 中 timer 启动前调用 `_generate_initial_orders()`。

**理由**: 设计文档未明确要求开局必须有订单，但 UX 角度空的订单区是糟糕的新手体验。且函数已就绪，只需加一行调用。

### 3. generation_interval 默认值

**问题**: `@export var generation_interval: float = 10.0` 与 [cat_bakery_merge_design.md](cat_bakery_merge_design.md) §7 规定「每 60 秒」不一致。

**决策**: 改为 `60.0`，保留 `@export` 以便调试时覆盖。

**理由**: 10s 是开发调试值，应遵循设计文档。`@export` 保留调试灵活性。

### 4. AnimationPlayer 占位

**决策**: 在 scene 中新增空 `AnimationPlayer` 子节点，脚本中的 `_cache_children()` 引用已存在（第 59 行）。

## Risks / Trade-offs

- **[低风险] 场景重构可能影响现有布局**: 仅改名和结构对齐，不改 Control 尺寸/位置参数，布局不受影响
- **[无风险] `_generate_initial_orders()` 调用时机**: _ready 中 timer 启动前调用，gen 方法与 tick 方法共用同一逻辑
