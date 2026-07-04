## ADDED Requirements

### Requirement: Dictionary-based storage
The InventorySystem SHALL store items using a `Dictionary` where keys are strings in `"type_level"` format (e.g., `"bread_3"`) and values are integer counts.

#### Scenario: Add first item of a type
- **WHEN** a bread Lv3 item is added to an empty inventory
- **THEN** the dictionary contains `{"bread_3": 1}`

#### Scenario: Add duplicate item
- **WHEN** a bread Lv3 item is added to inventory that already has `{"bread_3": 1}`
- **THEN** the dictionary becomes `{"bread_3": 2}`

### Requirement: Capacity limit of 25
The InventorySystem SHALL enforce a maximum capacity of 25 items (total count across all types). The `add_item(item: Item) -> bool` method SHALL return `false` when the inventory is full.

#### Scenario: Add item within capacity
- **WHEN** `add_item(item)` is called with 20 items currently in inventory
- **THEN** the item is added, `inventory_changed` is emitted, and the method returns `true`

#### Scenario: Add item when full
- **WHEN** `add_item(item)` is called with 25 items currently in inventory
- **THEN** the item is NOT added, no signal is emitted, and the method returns `false`

### Requirement: Remove items
The InventorySystem SHALL provide a `remove_items(requirements: Dictionary) -> bool` method that deducts items from inventory. Returns `true` if all items were available, `false` if insufficient.

#### Scenario: Sufficient items
- **WHEN** `remove_items({"bread_3": 1, "dessert_2": 2})` is called with sufficient items in inventory
- **THEN** the counts are decremented and `inventory_changed` is emitted with the removed items

#### Scenario: Insufficient items
- **WHEN** `remove_items({"bread_3": 5})` is called with only 2 bread Lv3 items
- **THEN** no items are removed, no signal is emitted, and the method returns `false`

### Requirement: Check item availability
The InventorySystem SHALL provide a `has_items(requirements: Dictionary) -> bool` method that checks if all required items are available without removing them.

#### Scenario: Items available
- **WHEN** `has_items({"bread_3": 1})` is called with sufficient items
- **THEN** the method returns `true`

#### Scenario: Items not available
- **WHEN** `has_items({"drink_4": 1})` is called with no drink Lv4 items
- **THEN** the method returns `false`

### Requirement: Total item count
The InventorySystem SHALL provide a `get_count() -> int` method that returns the sum of all item counts.

#### Scenario: Count items
- **WHEN** inventory contains `{"bread_1": 3, "dessert_2": 1, "drink_3": 2}`
- **THEN** `get_count()` returns `6`

### Requirement: Inventory is storage only
The InventorySystem SHALL NOT participate in merging, grid operations, or any gameplay logic. It SHALL only store and retrieve items.

#### Scenario: No merge logic in inventory
- **WHEN** two bread Lv1 items exist in inventory
- **THEN** they remain as separate entries; no automatic merge occurs

### Requirement: One-way entry from grid collection
Items SHALL enter inventory ONLY through the `collect_request` flow. There SHALL be no mechanism to move items from inventory back to the grid.

#### Scenario: No inventory-to-grid path
- **WHEN** a player wants to use an inventory item on the grid
- **THEN** no API or method exists to support this operation

### Requirement: Collect request handling
The InventorySystem SHALL listen to `EventBus.collect_request(item, from_pos)` and either emit `EventBus.collect_done(item, from_pos)` on success or `EventBus.collect_failed(reason)` on failure.

#### Scenario: Collect success
- **WHEN** `collect_request` is received and inventory has space
- **THEN** the item is added to inventory, `collect_done(item, from_pos)` is emitted, and `inventory_changed` is emitted

#### Scenario: Collect failure
- **WHEN** `collect_request` is received and inventory is full
- **THEN** `collect_failed("inventory_full")` is emitted