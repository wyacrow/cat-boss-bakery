# order-system Delta Specification

## MODIFIED Requirements

### Requirement: Item type pool supports multiple chains

OrderSystem SHALL maintain an `ITEM_TYPES` constant array defining the available item types for order generation. Each item type in the pool SHALL have equal probability of being selected when generating order requirements. The pool SHALL be easily modifiable to support adding or removing chains during development.

#### Scenario: Order generates with items from multiple chains

- **WHEN** `ITEM_TYPES = ["drink", "bread"]` and an order with 1 item type is generated
- **THEN** the item type is randomly selected from drink or bread with equal probability

#### Scenario: Order with 2 item types selects distinct chains

- **WHEN** `ITEM_TYPES = ["drink", "bread"]` and an order with 2 item types is generated
- **THEN** the two types are distinct (one drink, one bread) — no duplicate type within a single order

#### Scenario: Single-chain pool still works

- **WHEN** `ITEM_TYPES = ["drink"]` and an order with 2 item types would be generated
- **THEN** the order falls back to 1 item type (since only 1 chain is available)
