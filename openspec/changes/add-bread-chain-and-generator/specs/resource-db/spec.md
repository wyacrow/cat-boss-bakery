# resource-db Delta Specification

## ADDED Requirements

### Requirement: ResourceDB provides item texture mapping for all three chains

ResourceDB SHALL maintain an `ITEM_TEXTURES` dictionary mapping `"type_level"` keys to texture paths for all three item chains (bread, dessert, drink). Each chain SHALL have 4 levels (1~4), totaling 12 entries. The `get_item_texture(key)` and `get_item_texture_by_parts(type, level)` methods SHALL return the corresponding Texture2D.

#### Scenario: Query bread Lv1 texture returns actual sprite

- **WHEN** `ResourceDB.get_item_texture("bread_1")` is called
- **THEN** the system returns the Texture2D loaded from `res://sprites/bread/resized-bread1.png`

#### Scenario: Query bread Lv3 texture returns actual sprite

- **WHEN** `ResourceDB.get_item_texture("bread_3")` is called
- **THEN** the system returns the Texture2D loaded from `res://sprites/bread/resized-bread3.png`

#### Scenario: Query bread Lv4 texture returns actual sprite

- **WHEN** `ResourceDB.get_item_texture_by_parts("bread", 4)` is called
- **THEN** the system returns the Texture2D loaded from `res://sprites/bread/resized-bread4.png`

### Requirement: ResourceDB provides item display name mapping

ResourceDB SHALL maintain an `ITEM_NAMES` dictionary mapping `"type_level"` keys to Chinese display names for all 12 item variants across the three chains.

#### Scenario: Query bread display names

- **WHEN** `ResourceDB.get_item_name("bread_1")` is called
- **THEN** returns "面粉"
- **WHEN** `ResourceDB.get_item_name("bread_3")` is called
- **THEN** returns "面包"

### Requirement: apply_texture_to sets texture from ITEM_TEXTURES

ResourceDB SHALL provide `apply_texture_to(item: Item)` that sets the item's `texture` field to the Texture2D from `ITEM_TEXTURES` matching `"type_level"`.

#### Scenario: Apply bread Lv2 texture to item

- **WHEN** `ResourceDB.apply_texture_to(bread_item)` where bread_item has type="bread", level=2
- **THEN** bread_item.texture is set to the Texture2D from `res://sprites/bread/resized-bread2.png`
