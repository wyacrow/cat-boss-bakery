## ADDED Requirements

### Requirement: 6x6 grid data structure
The GridBoard SHALL maintain a 6×6 array (`Array[Array]`) where each cell contains either an `Item` instance or `null`. The grid SHALL be data-driven with no per-cell scene nodes.

#### Scenario: Grid initialization
- **WHEN** the game starts
- **THEN** all 36 cells are initialized to `null`

### Requirement: Get item at position
The GridBoard SHALL provide a `get_item(pos: Vector2i) -> Item` method that returns the item at the given position, or `null` if empty.

#### Scenario: Get existing item
- **WHEN** `get_item(Vector2i(2, 3))` is called and cell (2,3) contains a bread Lv1 item
- **THEN** the method returns the bread Lv1 Item instance

#### Scenario: Get empty cell
- **WHEN** `get_item(Vector2i(0, 0))` is called and cell (0,0) is empty
- **THEN** the method returns `null`

### Requirement: Place item on grid
The GridBoard SHALL provide a `place_item(item: Item, pos: Vector2i) -> bool` method that places an item in an empty cell. Returns `true` on success, `false` if the cell is occupied or position is out of bounds.

#### Scenario: Place in empty cell
- **WHEN** `place_item(bread_lv1, Vector2i(1, 2))` is called on an empty cell
- **THEN** the item is placed, `grid_changed([Vector2i(1, 2)])` is emitted, and the method returns `true`

#### Scenario: Place in occupied cell
- **WHEN** `place_item(bread_lv1, Vector2i(1, 2))` is called on an occupied cell
- **THEN** no change occurs, no signal is emitted, and the method returns `false`

### Requirement: Remove item from grid
The GridBoard SHALL provide a `remove_item(pos: Vector2i) -> Item` method that removes and returns the item at the given position. Returns `null` if the cell is empty.

#### Scenario: Remove existing item
- **WHEN** `remove_item(Vector2i(0, 0))` is called on a cell containing a bread Lv2 item
- **THEN** the cell becomes empty, `grid_changed([Vector2i(0, 0)])` is emitted, and the bread Lv2 item is returned

### Requirement: Find empty cell
The GridBoard SHALL provide a `find_empty() -> Vector2i` method that returns the position of any empty cell. Returns `Vector2i(-1, -1)` if the grid is full.

#### Scenario: Find empty cell in partially filled grid
- **WHEN** `find_empty()` is called with some empty cells available
- **THEN** the method returns a valid `Vector2i` position of an empty cell

#### Scenario: Grid is full
- **WHEN** `find_empty()` is called with all 36 cells occupied
- **THEN** the method returns `Vector2i(-1, -1)`

### Requirement: Find random empty cell
The GridBoard SHALL provide a `find_empty_random() -> Vector2i` method that returns a uniformly random empty cell position. Returns `Vector2i(-1, -1)` if the grid is full. This method SHALL be used by GeneratorSystem to ensure items are placed at varied positions.

#### Scenario: Random placement distribution
- **WHEN** `find_empty_random()` is called multiple times on a partially filled grid
- **THEN** each empty cell has equal probability of being returned

#### Scenario: Grid is full
- **WHEN** `find_empty_random()` is called with all 36 cells occupied
- **THEN** the method returns `Vector2i(-1, -1)`

### Requirement: Grid full check
The GridBoard SHALL provide a `is_full() -> bool` method that returns `true` when all 36 cells are occupied.

#### Scenario: Grid full
- **WHEN** all 36 cells contain items
- **THEN** `is_full()` returns `true`

### Requirement: Grid changed signal
The GridBoard SHALL emit `EventBus.grid_changed(positions)` every time any cell content changes, where `positions` is an `Array[Vector2i]` listing all changed positions.

#### Scenario: Multiple changes in one operation
- **WHEN** a merge operation removes two items and places one result
- **THEN** `grid_changed` is emitted with all three affected positions

### Requirement: GridBoard listens to collect_done to remove collected items
The GridBoard SHALL listen to `EventBus.collect_done(item, from_pos)` and call `remove_item(from_pos)` to clear the grid cell after a successful collection. This completes the collection flow: CollectSystem detects triple-tap → `collect_request` → InventorySystem validates → `collect_done` → GridBoard removes from grid → `grid_changed`.

#### Scenario: Item removed from grid on collect_done
- **WHEN** `collect_done(<bread Lv2>, Vector2i(3, 2))` is emitted
- **THEN** GridBoard removes the item at position (3, 2), emits `grid_changed([Vector2i(3, 2)])`

#### Scenario: Grid position already empty on collect_done
- **WHEN** `collect_done(<item>, Vector2i(1, 1))` is emitted but cell (1, 1) is already empty
- **THEN** GridBoard logs a warning and no `grid_changed` is emitted (defensive no-op)