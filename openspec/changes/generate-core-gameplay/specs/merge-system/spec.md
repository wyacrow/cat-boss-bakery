## ADDED Requirements

### Requirement: Manual merge — select first item
The MergeSystem SHALL track a `selected_pos: Vector2i` (initialized to `Vector2i(-1, -1)` for "none"). When the player taps an occupied cell with no selection, that cell SHALL be selected.

#### Scenario: Select first item
- **WHEN** player taps cell (2, 3) containing a bread Lv1 item and no item is currently selected
- **THEN** `selected_pos` is set to `(2, 3)` and the cell is visually highlighted

### Requirement: Manual merge — select second item and attempt merge
When the player taps an occupied cell while a selection exists, the MergeSystem SHALL attempt to merge the two items. If they CAN merge (same type + same level, level < 4), the merge SHALL execute. If not, the selection SHALL be cancelled.

#### Scenario: Successful merge
- **WHEN** bread Lv1 at (0,0) is selected, then player taps bread Lv1 at (0,1)
- **THEN** both items are removed, a bread Lv2 is placed at (0,0), `grid_changed` and `merge_done` are emitted

#### Scenario: Failed merge — different types
- **WHEN** bread Lv1 at (0,0) is selected, then player taps dessert Lv1 at (0,1)
- **THEN** selection is cancelled, no items change, no signals are emitted

#### Scenario: Failed merge — different levels
- **WHEN** bread Lv1 at (0,0) is selected, then player taps bread Lv2 at (0,1)
- **THEN** selection is cancelled, no items change

#### Scenario: Failed merge — max level
- **WHEN** bread Lv4 at (0,0) is selected, then player taps bread Lv4 at (0,1)
- **THEN** selection is cancelled, no items change

### Requirement: Merge result placement
The merge result SHALL be placed at the position of the first selected item (item A). The position of the second item (item B) SHALL be cleared.

#### Scenario: Result at first position
- **WHEN** items at (2, 0) and (3, 0) merge
- **THEN** the result item is placed at (2, 0) and (3, 0) becomes empty

### Requirement: Auto-merge default off
The MergeSystem SHALL have `auto_merge_enabled: bool` defaulting to `false`. Auto-merge SHALL NOT activate unless toggled ON by the player.

#### Scenario: Game start
- **WHEN** the game starts
- **THEN** `auto_merge_enabled` is `false`

### Requirement: Auto-merge scan on grid change
When `auto_merge_enabled` is `true`, the MergeSystem SHALL scan the entire grid for any mergeable pair on every `grid_changed` signal. It SHALL find the first mergeable pair and execute the merge.

#### Scenario: Auto-merge triggers
- **WHEN** `auto_merge_enabled` is `true` and two bread Lv1 items exist on the grid
- **THEN** after a `grid_changed` signal, the system finds and merges the first pair

### Requirement: Auto-merge chain with 0.1s interval
After a successful auto-merge, the system SHALL wait 0.1 seconds before scanning again. This chain SHALL continue until no more mergeable pairs exist.

#### Scenario: Chain reaction
- **WHEN** auto-merge is ON and 4 bread Lv1 items exist on the grid
- **THEN** the system merges the first pair into bread Lv2, waits 0.1s, then merges the other pair into bread Lv2, then waits 0.1s, then merges the two Lv2 into bread Lv3, then stops

### Requirement: Auto-merge and manual merge coexistence
When auto-merge is enabled, manual merges SHALL still be allowed. Auto-merge SHALL re-validate cell contents before executing to avoid conflicts with concurrent manual merges.

#### Scenario: Manual merge during auto-merge chain
- **WHEN** auto-merge is chaining and the player manually merges two items
- **THEN** the next auto-merge scan skips positions that changed due to the manual merge

### Requirement: Auto-merge toggle
The MergeSystem SHALL provide a `toggle_auto_merge()` method that flips `auto_merge_enabled` and emits `EventBus.auto_merge_toggled(enabled)`.

#### Scenario: Toggle auto-merge ON
- **WHEN** `toggle_auto_merge()` is called and `auto_merge_enabled` is `false`
- **THEN** `auto_merge_enabled` becomes `true` and `auto_merge_toggled(true)` is emitted

### Requirement: Selection cleared on grid change
The MergeSystem SHALL listen to `EventBus.grid_changed` and validate that `selected_pos` still contains the same item. If the cell is empty or contains a different item (e.g., due to collection or another merge), `selected_pos` SHALL be reset to `Vector2i(-1, -1)`.

#### Scenario: Selected item collected
- **WHEN** player has selected item at (2, 3) and that item is collected via triple-tap
- **THEN** `grid_changed` fires, MergeSystem detects (2, 3) is now empty, and `selected_pos` resets to `(-1, -1)`

#### Scenario: Selected item merged by auto-merge
- **WHEN** player has selected item at (1, 0) and auto-merge consumes it
- **THEN** `grid_changed` fires, MergeSystem detects (1, 0) no longer holds the original item, and `selected_pos` resets to `(-1, -1)`