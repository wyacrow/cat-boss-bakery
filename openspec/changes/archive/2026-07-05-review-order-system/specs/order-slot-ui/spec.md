## ADDED Requirements

### Requirement: Scene node structure matches script references
The order_slot.tscn scene SHALL contain child nodes with names matching the script's _cache_children() references: CatIcon, ItemContainer (with ItemBtn template), RewardBtn (with CurrencySet containing CurrencyIcon and Label), and AnimationPlayer.

#### Scenario: Script caches all scene nodes correctly
- **WHEN** OrderSlot._ready() executes _cache_children()
- **THEN** _cat_icon references the CatIcon TextureRect
- **THEN** _req_container references the ItemContainer Control
- **THEN** _item_template references ItemContainer/ItemBtn (hidden template for runtime clone)
- **THEN** _gold_icon references the CurrencyIcon TextureRect inside RewardBtn/CurrencySet
- **THEN** _reward_label references the Label inside RewardBtn/CurrencySet
- **THEN** _anim_player references the AnimationPlayer node

### Requirement: Requirements display clones ItemBtn template from scene
The script SHALL dynamically clone the scene's ItemBtn template node inside ItemContainer to display each requirement's icon and quantity. Font size and color SHALL be read from the template's LabelSettings at cache time (43px, brown).

#### Scenario: set_order with 2 requirements
- **WHEN** set_order is called with an OrderData having {"dessert_2": 2, "drink_3": 1}
- **THEN** ItemContainer has exactly 2 cloned ItemBtn children (excluding the hidden template)
- **THEN** each clone's ItemTexture displays the correct item icon from ResourceDB
- **THEN** each clone's ItemCountLabel displays "×N" quantity text
- **THEN** rows are arranged vertically: single item fills container, dual items split top/bottom with adjusted icon sizes (120px / 80px)

### Requirement: Entire card area is clickable
The OrderSlot SHALL set mouse_filter=STOP on itself and mouse_filter=IGNORE on all child Control nodes, so clicks anywhere on the card (cat icon, item area, reward area) are handled by the card's gui_input handler.

#### Scenario: Click on cat icon area
- **WHEN** user clicks the CatIcon region of an OrderSlot with a valid order
- **THEN** the click triggers _on_gui_input → play_shake_animation → _submit

### Requirement: Click triggers shake animation
When a valid (non-empty) OrderSlot is clicked, a three-stage elastic scale animation SHALL play around the card's center before submitting: 1.0 → 1.15 (40% duration) → 0.95 (30%) → 1.0 (30%), using TRANS_QUAD EASE_OUT, total 0.3s.

#### Scenario: Click on filled order slot
- **WHEN** user clicks an OrderSlot with a valid order
- **THEN** the card scales up to 1.15, then down to 0.95, then returns to 1.0
- **THEN** scaling pivots around the card's center (pivot_offset = size / 2)
- **THEN** submit_order is called after the animation completes
