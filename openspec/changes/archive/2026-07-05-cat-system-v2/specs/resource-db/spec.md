## ADDED Requirements

### Requirement: ResourceDB provides separate cat sprite and customer cat mappings

ResourceDB SHALL maintain two distinct texture path dictionaries: `CAT_SPRITES` for player-owned cat images (used in collection pages, main screen decorations) and `CUSTOMER_CAT_TEXTURES` for order NPC customer cat images. The two pools SHALL be independently queryable.

#### Scenario: Query player cat sprite by cat_id

- **WHEN** `ResourceDB.get_cat_sprite("bread_cat")` is called
- **THEN** the system returns the Texture2D loaded from the path in `CAT_SPRITES["bread_cat"]`

#### Scenario: Query customer cat texture by customer_id

- **WHEN** `ResourceDB.get_customer_cat_texture("customer_cat_03")` is called
- **THEN** the system returns the Texture2D loaded from the path in `CUSTOMER_CAT_TEXTURES["customer_cat_03"]`

#### Scenario: Query with unknown key returns null

- **WHEN** `ResourceDB.get_cat_sprite("nonexistent_cat")` is called
- **THEN** the system returns `null` without throwing an error

### Requirement: Customer cat pool contains at least 5 entries

The `CUSTOMER_CAT_TEXTURES` dictionary SHALL define 5 entries with keys `customer_cat_01` through `customer_cat_05`. V1 SHALL use `res://sprites/cat.png` as the placeholder texture for all entries.

#### Scenario: Pool returns all defined customer cat IDs

- **WHEN** `ResourceDB.get_all_customer_cat_ids()` is called
- **THEN** the system returns an array containing exactly `["customer_cat_01", "customer_cat_02", "customer_cat_03", "customer_cat_04", "customer_cat_05"]`

### Requirement: Texture loading uses lazy caching

ResourceDB SHALL load textures on first access via `load()` and cache the result in a static `_texture_cache` dictionary. Subsequent queries for the same path SHALL return the cached reference. A `clear_cache()` method SHALL allow flushing the cache for asset pack hot-swapping.

#### Scenario: First access loads and caches

- **WHEN** `ResourceDB.get_cat_sprite("bread_cat")` is called for the first time
- **THEN** the texture is loaded from disk and stored in `_texture_cache`

#### Scenario: Second access returns cached reference

- **WHEN** `ResourceDB.get_cat_sprite("bread_cat")` is called again after the first access
- **THEN** the cached Texture2D reference is returned without re-loading from disk

### Requirement: ResourceDB provides UI texture mapping

ResourceDB SHALL maintain a `UI_TEXTURES` dictionary mapping UI element keys (e.g., `gold_icon`, `reward_btn_bg`) to texture paths, queryable via `get_ui_texture(ui_key: String)`.

#### Scenario: Query gold icon texture

- **WHEN** `ResourceDB.get_ui_texture("gold_icon")` is called
- **THEN** the system returns the Texture2D loaded from `res://sprites/gold.png`
