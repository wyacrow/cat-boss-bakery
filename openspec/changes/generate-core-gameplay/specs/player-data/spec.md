## ADDED Requirements

### Requirement: PlayerData is a Godot Autoload singleton
The PlayerData SHALL be registered as a Godot Autoload named `PlayerData` at `res://scripts/core/PlayerData.gd`. It SHALL extend `Node` and serve as the central store for all player-owned numeric values.

#### Scenario: Autoload availability
- **WHEN** any node enters the scene tree
- **THEN** `PlayerData` is accessible as a global singleton without requiring `get_node()` or path references

### Requirement: Gold tracking
The PlayerData SHALL maintain a `gold: int` field (initialized to 0) as the single source of truth for the player's current gold amount.

#### Scenario: Initial gold
- **WHEN** the game starts
- **THEN** `gold` equals `0`

### Requirement: Add gold
The PlayerData SHALL provide an `add_gold(amount: int)` method that increases gold and emits `EventBus.gold_changed(gold)`.

#### Scenario: Add gold from order completion
- **WHEN** `add_gold(60)` is called with `gold` = 100
- **THEN** `gold` becomes 160 and `gold_changed(160)` is emitted

### Requirement: Spend gold
The PlayerData SHALL provide a `spend_gold(amount: int) -> bool` method that decreases gold if sufficient. Returns `true` on success, `false` if insufficient. Emits `EventBus.gold_changed(gold)` only on success.

#### Scenario: Sufficient gold
- **WHEN** `spend_gold(30)` is called with `gold` = 100
- **THEN** `gold` becomes 70, `gold_changed(70)` is emitted, and the method returns `true`

#### Scenario: Insufficient gold
- **WHEN** `spend_gold(200)` is called with `gold` = 100
- **THEN** `gold` remains 100, no signal is emitted, and the method returns `false`

### Requirement: Get gold
The PlayerData SHALL provide a `get_gold() -> int` method that returns the current gold amount.

#### Scenario: Query gold
- **WHEN** `get_gold()` is called with `gold` = 160
- **THEN** the method returns `160`

### Requirement: Order completion triggers gold
The PlayerData SHALL listen to `EventBus.order_completed(order_id, reward_gold)` and call `add_gold(reward_gold)` to credit the player.

#### Scenario: Gold credited on order completion
- **WHEN** `order_completed("order_001", 60)` is emitted
- **THEN** PlayerData adds 60 gold and emits `gold_changed` with the new total

### Requirement: Extensible for future player values
The PlayerData SHALL be structured to support additional player-owned values in future versions (e.g., gems, total_orders_completed, play_time). V1 SHALL only implement gold.

#### Scenario: Future-proof structure
- **WHEN** a new player value is needed in V2
- **THEN** it can be added to PlayerData without modifying other systems
