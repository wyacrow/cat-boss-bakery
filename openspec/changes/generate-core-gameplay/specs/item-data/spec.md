## ADDED Requirements

### Requirement: Item data class extends RefCounted
The Item class SHALL extend `RefCounted` and be located at `res://scripts/data/Item.gd`.

#### Scenario: Item instantiation
- **WHEN** code creates `Item.new("bread", 3)`
- **THEN** an Item instance is created with `type = "bread"` and `level = 3`

### Requirement: Item type field
The Item class SHALL have a `type: String` field that MUST be one of `"bread"`, `"dessert"`, or `"drink"`.

#### Scenario: Valid type assignment
- **WHEN** an Item is created with type "bread"
- **THEN** `item.type` equals `"bread"`

### Requirement: Item level field
The Item class SHALL have a `level: int` field that MUST be in range 1-4.

#### Scenario: Valid level assignment
- **WHEN** an Item is created with level 2
- **THEN** `item.level` equals `2`

### Requirement: Item display name
The Item class SHALL provide a `get_display_name() -> String` method that returns a human-readable name based on type and level.

#### Scenario: Display name for bread Lv3
- **WHEN** `item.get_display_name()` is called on a bread Lv3 item
- **THEN** the method returns "面包" (or equivalent display name for bread Lv3)

### Requirement: Item key for inventory storage
The Item class SHALL provide a `get_key() -> String` method that returns `"{type}_{level}"` format.

#### Scenario: Key generation
- **WHEN** `item.get_key()` is called on a dessert Lv2 item
- **THEN** the method returns `"dessert_2"`

### Requirement: Item merge compatibility check
The Item class SHALL provide a `can_merge_with(other: Item) -> bool` method that returns true only when both items have the same type AND same level AND level is less than 4.

#### Scenario: Compatible items
- **WHEN** `bread_lv1.can_merge_with(bread_lv1)` is called
- **THEN** the method returns `true`

#### Scenario: Different type items
- **WHEN** `bread_lv1.can_merge_with(dessert_lv1)` is called
- **THEN** the method returns `false`

#### Scenario: Different level items
- **WHEN** `bread_lv1.can_merge_with(bread_lv2)` is called
- **THEN** the method returns `false`

#### Scenario: Max level items
- **WHEN** `bread_lv4.can_merge_with(bread_lv4)` is called
- **THEN** the method returns `false`

### Requirement: Item merge result
The Item class SHALL provide a `get_merge_result() -> Item` method that returns a new Item with the same type and level+1.

#### Scenario: Merge result
- **WHEN** `bread_lv2.get_merge_result()` is called
- **THEN** the method returns a new `Item` with `type = "bread"` and `level = 3`

### Requirement: Three item chains with four levels each
The game SHALL support exactly 12 item variants: 3 chains (bread, dessert, drink) × 4 levels (Lv1-Lv4).

#### Scenario: Complete item catalog
- **WHEN** all 12 item variants are enumerated
- **THEN** the catalog contains bread Lv1-4, dessert Lv1-4, and drink Lv1-4