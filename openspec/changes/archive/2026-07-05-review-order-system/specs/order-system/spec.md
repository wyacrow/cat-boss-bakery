## ADDED Requirements

### Requirement: Initial orders generated on startup
OrderSystem SHALL generate initial orders to fill all 3 slots when the system starts, before the first timer tick.

#### Scenario: System starts with empty slots
- **WHEN** OrderSystem._ready() executes
- **THEN** all 3 order slots are populated with valid OrderData objects
- **THEN** EventBus.order_generated is emitted once per order

### Requirement: Generation interval matches design spec
OrderSystem SHALL use a default generation interval of 60 seconds.

#### Scenario: Default timer interval
- **WHEN** OrderSystem starts with default export values
- **THEN** new orders are generated every 60 seconds when slots are not full

### Requirement: New order fills first available empty slot
When the generation timer fires and there are empty slots, a new order SHALL be placed in the first empty slot (lowest index).

#### Scenario: One slot empty after submission
- **WHEN** a generation tick fires and slot 1 is empty (after order in slot 1 was submitted)
- **THEN** a new order is created and placed in slot 1
