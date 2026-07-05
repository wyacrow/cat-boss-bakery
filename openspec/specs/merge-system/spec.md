# Merge System

## Purpose

纯手动二合合成系统 — 玩家点击选中两个同 type 同 level 的物品执行合成（2×LvN → LvN+1），Lv4 为终点。不包含自动合成、连锁扫描或合成开关功能。

## Requirements

### Requirement: MergeSystem 为纯手动二合系统
MergeSystem SHALL 仅支持手动合成模式：玩家选中物品A → 选中物品B → type和level相同即执行合成。系统不包含自动扫描、连锁合成、或合成开关功能。

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

### Requirement: Selection cleared on grid change
The MergeSystem SHALL listen to `EventBus.grid_changed` and validate that `selected_pos` still contains the same item. If the cell is empty or contains a different item, `selected_pos` SHALL be reset to `Vector2i(-1, -1)`.

#### Scenario: Selected item consumed by order
- **WHEN** player has selected item at (2, 3) and an order submission consumes that item from the board
- **THEN** `grid_changed` fires, MergeSystem detects (2, 3) is now empty, and `selected_pos` resets to `(-1, -1)`

### Requirement: No auto-merge functionality
The MergeSystem SHALL NOT include auto-merge scanning, chain merging, or an auto-merge toggle. No `auto_merge_toggled` signal SHALL exist in EventBus.

#### Scenario: Game start with no auto-merge
- **WHEN** the game starts
- **THEN** only manual merge is available; there is no auto-merge toggle in the UI or in code
