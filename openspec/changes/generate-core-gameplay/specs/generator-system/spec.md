## ADDED Requirements

### Requirement: Single generator produces Lv1 items
The GeneratorSystem SHALL maintain exactly one generator that spawns Lv1 items only. It SHALL NOT produce items of level 2 or higher.

#### Scenario: Generate Lv1 item
- **WHEN** the generator is triggered
- **THEN** the resulting item has `level == 1`

### Requirement: Generate method with result codes
The GeneratorSystem SHALL provide a `try_generate() -> int` method that attempts to consume 1 stamina and create 1 Lv1 item on a random empty grid cell. Return values:
- `0` — success: item generated and placed
- `1` — failed: insufficient stamina
- `2` — failed: grid is full

The UI layer (HUD generate button) SHALL be connected to this method via signal wiring in `Main._ready()`. The UI SHALL read the return value and display appropriate Toast feedback for non-zero results.

#### Scenario: Generate success
- **WHEN** `try_generate()` is called with `current_stamina >= 1` and grid has empty cells
- **THEN** 1 stamina is consumed, 1 Lv1 item is created and placed, and the method returns `0`

### Requirement: Stamina cost for generation
The GeneratorSystem SHALL consume 1 stamina point per item generated. If stamina is insufficient, no item SHALL be generated and `try_generate()` SHALL return `1`.

#### Scenario: Generate with stamina
- **WHEN** generator is triggered and `current_stamina >= 1`
- **THEN** 1 stamina is consumed and 1 Lv1 item is created

#### Scenario: Generate without stamina
- **WHEN** `try_generate()` is called with `current_stamina == 0`
- **THEN** no item is created, no stamina is consumed, and the method returns `1`

### Requirement: Random item type distribution
The GeneratorSystem SHALL randomly select one of three types with equal probability: bread (33%), dessert (33%), drink (33%).

#### Scenario: Random distribution
- **WHEN** the generator produces 1000 items
- **THEN** each type (bread, dessert, drink) appears approximately 333 times (± statistical variance)

### Requirement: Auto-placement on grid
The GeneratorSystem SHALL automatically place the generated item into a random empty cell on the grid. If the grid is full, generation SHALL be refused without consuming stamina.

#### Scenario: Place in empty cell
- **WHEN** an item is generated and the grid has at least one empty cell
- **THEN** the item is placed in a randomly selected empty cell and `grid_changed` is emitted

#### Scenario: Grid full — generation refused
- **WHEN** `try_generate()` is called but the grid has no empty cells
- **THEN** no stamina is consumed, no item is created, and the method returns `2`. The UI layer displays a Toast with "棋盘已满" (grid full) message.

### Requirement: Generator does not participate in merge or orders
The GeneratorSystem SHALL only produce items and place them on the grid. It SHALL NOT interact with merge logic, orders, or inventory.

#### Scenario: Generator output is only Lv1 items to grid
- **WHEN** any item is generated
- **THEN** it is placed on the grid; it is never added to inventory or used in orders directly