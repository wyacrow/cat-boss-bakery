## ADDED Requirements

### Requirement: Three order slots
The OrderSystem SHALL maintain exactly 3 order slots. Only one order per slot. When all 3 slots are occupied, no new orders SHALL be generated.

#### Scenario: Slots available
- **WHEN** the game starts
- **THEN** all 3 order slots are empty

### Requirement: Automatic order generation every 60 seconds
The OrderSystem SHALL generate a new order every 60 seconds if at least one slot is empty. Generation SHALL use a `Timer` node with 60-second interval.

#### Scenario: New order generated
- **WHEN** 60 seconds pass with an empty slot
- **THEN** a new order is created in the empty slot and `order_generated(order_id, requirements)` is emitted

#### Scenario: All slots full
- **WHEN** 60 seconds pass with all 3 slots occupied
- **THEN** no new order is generated

### Requirement: Initial orders on game start
The OrderSystem SHALL generate 3 initial orders immediately when the game starts (in `_ready()`), filling all 3 slots. The 60-second timer SHALL begin counting after these initial orders are created.

#### Scenario: Game start with initial orders
- **WHEN** the game starts
- **THEN** 3 orders are immediately generated and all 3 slots are filled

### Requirement: Order requirements only Lv2+
The OrderSystem SHALL only generate orders requiring items of level 2, 3, or 4. Lv1 items SHALL NOT appear in any order requirement.

#### Scenario: Generated order contains only Lv2+
- **WHEN** a new order is generated
- **THEN** all required items have `level >= 2`

### Requirement: Random order content
Each order SHALL require 1-2 item types, with 1-3 quantity of each type. The base reward SHALL be calculated as `Σ(item.level × 10 × quantity)`.

#### Item type selection
Each required item type SHALL be selected with equal probability from all 3 chains (bread 33% / dessert 33% / drink 33%). When an order requires 2 item types, each type SHALL be independently selected (duplicates allowed — reroll if same type selected twice).

#### Item level distribution
Item levels SHALL be weighted toward lower levels to match merge difficulty:
- Lv2: 50% probability
- Lv3: 35% probability
- Lv4: 15% probability

This ensures orders are achievable early-game while still providing late-game challenge.

#### Scenario: Single-item order
- **WHEN** an order is generated requiring bread Lv3 × 2
- **THEN** the base reward is `3 × 10 × 2 = 60` gold

#### Scenario: Multi-item order
- **WHEN** an order is generated requiring bread Lv3 × 1 and dessert Lv2 × 2
- **THEN** the base reward is `(3×10×1) + (2×10×2) = 70` gold

### Requirement: Submit order validation
The OrderSystem SHALL provide a `submit_order(order_id: String) -> bool` method. It SHALL validate requirements against InventorySystem, and if all items are available, complete the order.

#### Scenario: Successful submission
- **WHEN** `submit_order("order_001")` is called and inventory has all required items
- **THEN** items are removed from inventory, `order_completed(order_id, final_reward)` is emitted (PlayerData listens and credits gold), and the slot is cleared

#### Scenario: Failed submission
- **WHEN** `submit_order("order_001")` is called and inventory lacks required items
- **THEN** no items are removed, no gold is added, and the method returns `false`

### Requirement: Cat gold multiplier
The final reward SHALL be calculated as `base_reward × cat_gold_multiplier`. When coffee cat is active, the multiplier SHALL be 1.2.

#### Scenario: Coffee cat reward boost
- **WHEN** an order with base reward 50 is completed with coffee cat active
- **THEN** the final reward is `50 × 1.2 = 60` gold

### Requirement: Orders never expire in V1
The OrderSystem SHALL NOT expire or cancel orders. Orders SHALL remain in their slots until the player submits them.

#### Scenario: Order persists indefinitely
- **WHEN** an order has been sitting for 10 minutes
- **THEN** the order remains valid and submittable

### Requirement: Orders do not interact with grid
The OrderSystem SHALL only interact with InventorySystem. It SHALL NOT read from, write to, or modify the grid in any way.

#### Scenario: Order submission only checks inventory
- **WHEN** `submit_order` is called
- **THEN** only InventorySystem is queried; GridBoard is never accessed