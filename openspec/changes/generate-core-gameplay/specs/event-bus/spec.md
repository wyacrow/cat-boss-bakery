## ADDED Requirements

### Requirement: EventBus is a Godot Autoload singleton
The EventBus SHALL be registered as a Godot Autoload named `EventBus` at `res://scripts/core/EventBus.gd`. It SHALL extend `Node` and serve as the single global signal bus for all inter-system communication.

#### Scenario: Autoload availability
- **WHEN** any node enters the scene tree
- **THEN** `EventBus` is accessible as a global singleton without requiring `get_node()` or path references

### Requirement: Stamina changed signal
The EventBus SHALL provide a `stamina_changed` signal with signature `(current: int, max_stamina: int)`.

#### Scenario: Stamina consumption broadcast
- **WHEN** StaminaSystem consumes 1 stamina point
- **THEN** `stamina_changed(19, 20)` is emitted to all connected listeners

### Requirement: Grid changed signal
The EventBus SHALL provide a `grid_changed` signal with signature `(positions: Array[Vector2i])` listing all grid positions that changed.

#### Scenario: Item placement broadcast
- **WHEN** GridBoard places an item at position (2, 3)
- **THEN** `grid_changed([Vector2i(2, 3)])` is emitted

### Requirement: Merge done signal
The EventBus SHALL provide a `merge_done` signal with signature `(from_pos: Vector2i, to_pos: Vector2i, result_item: Item)`.

#### Scenario: Successful merge broadcast
- **WHEN** two bread Lv1 items at (0,0) and (0,1) merge into bread Lv2 at (0,0)
- **THEN** `merge_done(Vector2i(0,1), Vector2i(0,0), <bread Lv2 Item>)` is emitted

### Requirement: Inventory changed signal
The EventBus SHALL provide an `inventory_changed` signal with signature `(added_items: Array[Item], removed_items: Array[Item])`.

#### Scenario: Item collection broadcast
- **WHEN** a bread Lv2 item is collected into inventory
- **THEN** `inventory_changed([<bread Lv2 Item>], [])` is emitted

### Requirement: Order completed signal
The EventBus SHALL provide an `order_completed` signal with signature `(order_id: String, reward_gold: int)`.

#### Scenario: Order submission broadcast
- **WHEN** order "order_001" is completed with a 50 gold reward
- **THEN** `order_completed("order_001", 50)` is emitted

### Requirement: Order generated signal
The EventBus SHALL provide an `order_generated` signal with signature `(order_id: String, requirements: Dictionary)`.

#### Scenario: New order broadcast
- **WHEN** OrderSystem generates a new order requiring dessert Lv2 x1 and bread Lv3 x2
- **THEN** `order_generated("order_002", {"dessert_2": 1, "bread_3": 2})` is emitted

### Requirement: Collect request signal
The EventBus SHALL provide a `collect_request` signal with signature `(item: Item, from_pos: Vector2i)`.

#### Scenario: Triple-tap collection request
- **WHEN** player triple-taps a bread Lv3 item at grid position (3, 2)
- **THEN** `collect_request(<bread Lv3 Item>, Vector2i(3, 2))` is emitted

### Requirement: Collect done signal
The EventBus SHALL provide a `collect_done` signal with signature `(item: Item, from_pos: Vector2i)`.

#### Scenario: Successful collection broadcast
- **WHEN** InventorySystem successfully adds the collected item from grid position (2, 3)
- **THEN** `collect_done(<item>, Vector2i(2, 3))` is emitted, and GridBoard listens to this signal to remove the item from the grid

### Requirement: Collect failed signal
The EventBus SHALL provide a `collect_failed` signal with signature `(reason: String)`.

#### Scenario: Inventory full collection failure
- **WHEN** InventorySystem cannot accept an item because inventory is full
- **THEN** `collect_failed("inventory_full")` is emitted

### Requirement: Auto merge toggled signal
The EventBus SHALL provide an `auto_merge_toggled` signal with signature `(enabled: bool)`.

#### Scenario: Auto merge toggle broadcast
- **WHEN** player toggles the auto-merge switch to ON
- **THEN** `auto_merge_toggled(true)` is emitted

### Requirement: Gold changed signal
The EventBus SHALL provide a `gold_changed` signal with signature `(current: int)`.

#### Scenario: Gold update broadcast
- **WHEN** player's gold changes from 200 to 250
- **THEN** `gold_changed(250)` is emitted