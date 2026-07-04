## ADDED Requirements

### Requirement: Triple-tap detection within 0.8 seconds
The CollectSystem SHALL detect when the player taps the same grid cell 3 times within a 0.8-second window. The detection SHALL use a 50% cell radius tolerance for touch position matching.

#### Scenario: Successful triple-tap
- **WHEN** player taps cell (2, 3) three times within 0.8 seconds
- **THEN** the system detects a valid triple-tap and emits `collect_request(item, Vector2i(2, 3))`

#### Scenario: Too slow triple-tap
- **WHEN** player taps cell (2, 3) once, waits 1.0 second, then taps twice more
- **THEN** the click counter resets after the first tap and no collect request is emitted

#### Scenario: Different cell taps
- **WHEN** player taps cell (2, 3) once, then taps cell (3, 3) once
- **THEN** the click counter resets to 1 for cell (3, 3)

### Requirement: Collect request emission
When a valid triple-tap is detected, the CollectSystem SHALL emit `EventBus.collect_request(item, from_pos)` where `item` is the Item at that grid position and `from_pos` is the grid position.

#### Scenario: Emit collect request
- **WHEN** triple-tap is detected on a cell containing a cake Lv2 item
- **THEN** `collect_request(dessert_lv2_item, Vector2i(x, y))` is emitted

### Requirement: Triple-tap takes priority over merge selection
The CollectSystem's triple-tap detection SHALL take priority over the MergeSystem's selection state. If a player triple-taps an item that is currently selected for merging, the item SHALL be collected and the selection SHALL be cancelled.

#### Scenario: Triple-tap on selected item
- **WHEN** bread Lv1 is selected (merge state), then player triple-taps it
- **THEN** the item is collected, selection is cancelled

### Requirement: Collect done handling
When the CollectSystem receives `collect_done(item, from_pos)`, it SHALL reset its internal click counter and tracking state. The `from_pos` parameter allows GridBoard to identify and clear the correct grid cell.

#### Scenario: Reset after successful collection
- **WHEN** `collect_done(<item>, Vector2i(2, 3))` is received
- **THEN** `click_count` resets to 0 and `last_click_pos` is cleared

### Requirement: Collect failed handling
When the CollectSystem receives `collect_failed`, it SHALL reset its internal state without removing the item from the grid.

#### Scenario: Inventory full
- **WHEN** `collect_failed("inventory_full")` is received
- **THEN** click counter resets and the item remains on the grid

### Requirement: Visual feedback on each tap
The CollectSystem SHALL trigger a visual feedback (e.g., scale pulse animation) on each valid tap within the triple-tap sequence. The third successful tap SHALL trigger a distinct collection animation.

#### Scenario: Tap feedback sequence
- **WHEN** player taps cell once: subtle bounce animation
- **WHEN** player taps same cell twice: another subtle bounce
- **WHEN** player taps same cell third time: collection animation plays