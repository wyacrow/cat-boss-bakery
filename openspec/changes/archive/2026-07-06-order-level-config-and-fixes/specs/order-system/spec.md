# Order System (Delta)

## MODIFIED: Order generation changed to level-config based

### Requirement: Orders loaded from level config instead of auto-generated
OrderSystem SHALL load orders from `LevelConfig` when `load_level()` is called, instead of generating random orders on a timer.

#### Scenario: Level loads with pre-defined orders
- **WHEN** `OrderSystem.load_level("level_01")` is called
- **THEN** all orders from the level config are queued in `_order_queue`
- **THEN** 2 slot-filling orders are immediately placed in visible slots via `_fill_slots()`
- **THEN** EventBus.order_generated is emitted once per created order

### Requirement: Next order fills slot after animation completes
When an order is submitted and the slot freed, the next order SHALL wait for the disappear animation to finish before appearing, triggered by `EventBus.order_slot_freed`.

#### Scenario: Order submitted, next waits for animation
- **WHEN** `submit_order()` succeeds
- **THEN** the slot is cleared but `_fill_slots()` is NOT called immediately
- **THEN** after OrderBarManager finishes disappear animation, `EventBus.order_slot_freed` is emitted
- **THEN** OrderSystem responds by calling `_fill_slots()` to place the next queued order

## REMOVED: Timer-based auto-generation

### Requirement: ~~Generation interval matches design spec~~
**REMOVED.** Timer-based generation is replaced by level-config driven loading.

### Requirement: ~~New order fills first available empty slot~~
**REMOVED.** Slot filling is now controlled by `_fill_slots()` triggered by `order_slot_freed` signal.
