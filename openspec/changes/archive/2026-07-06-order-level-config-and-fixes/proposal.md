## Why

订单系统当前为定时随机生成，无法控制难度曲线和关卡节奏。需要改为配表关卡制，让策划能逐关配置订单内容，同时修复几个小的体验问题。

## What Changes

- **BREAKING**: 订单系统从定时自动生成改为关卡配表驱动，移除随机生成逻辑
- 新增 `LevelConfig` 配表，定义每关的订单列表（玩家完成一个从队列补入下一个）
- 订单完成后等消失动画播完才补入新订单（`order_slot_freed` 信号机制）
- 生成器图标以中心为锚点放大 1.2 倍（素材图像占比过小）
- 体力上限从 20 改为 50

## Capabilities

### New Capabilities
- `order-level-config`: 关卡配表制的订单系统，LevelConfig 定义每关订单列表，OrderSystem 改为队列驱动

### Modified Capabilities
<!-- No existing specs modified -->

## Impact

- `scripts/systems/OrderSystem.gd` — 重写（移除定时器/随机生成，新增 load_level/fill_slots/队列机制）
- `scripts/data/LevelConfig.gd` — 新建（关卡配表）
- `scripts/data/OrderData.gd` — 新增 level_id 字段
- `scripts/core/EventBus.gd` — 新增 level_completed/level_loaded/order_slot_freed 信号
- `scripts/core/GameStat.gd` — 移除重复的 order_progress_changed emit
- `scripts/core/GameScene.gd` — 新增 load_level 调用
- `scripts/ui/components/order_bar_manager.gd` — 动画结束后 emit order_slot_freed
- `scripts/ui/components/item_cell_button.gd` — 生成器图标 scale 1.2x
- `scripts/systems/StaminaSystem.gd` — max_stamina 20 → 50
