# Order Level Config

## Purpose

`LevelConfig` 是一个只读配表（RefCounted），定义每个关卡的订单列表。OrderSystem 通过此表加载关卡订单队列，实现关卡制订单流。

## Requirements

### Requirement: Level config defines ordered list of orders
LevelConfig SHALL store each level as a dictionary with a `name` string and an `orders` array of order configurations.

#### Scenario: Level 01 has 3 orders with Lv2/Lv3 items
- **WHEN** `LevelConfig.get_level("level_01")` is called
- **THEN** a dictionary with "name" and "orders" keys is returned
- **THEN** orders array contains exactly 3 entries, each with `requirements`, `base_reward`, and `customer_cat`

### Requirement: Get next level ID
LevelConfig SHALL provide `get_next_level_id(current)` to return the next level ID in order, or empty string if it is the last level.

#### Scenario: Advance from level_01 to level_02
- **WHEN** `LevelConfig.get_next_level_id("level_01")` is called
- **THEN** returns `"level_02"`

### Requirement: Level progress tracked per-level
When a level is loaded, the progress tracking SHALL reset to 0/N where N is the total orders in that level, emitted via `EventBus.order_progress_changed`.

#### Scenario: Level loads, progress resets
- **WHEN** `OrderSystem.load_level("level_01")` is called
- **THEN** `EventBus.level_loaded("level_01", 3)` is emitted
- **THEN** `EventBus.order_progress_changed(0, 3)` is emitted

### Requirement: Level completion auto-advances
When all orders in a level are completed, OrderSystem SHALL emit `EventBus.level_completed` and automatically call `advance_to_next_level()`.

#### Scenario: All orders done, auto-advance
- **WHEN** `_level_orders_completed >= _level_total_orders`
- **THEN** `EventBus.level_completed(level_id)` is emitted
- **THEN** `advance_to_next_level()` is called, loading the next level
