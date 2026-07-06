# typed-generator Specification

## Purpose

生成器系统支持类型化生成器，每个生成器实例可指定产出物品类型（如 drink、bread），替代硬编码的单一类型池。棋盘上可放置多个类型不同的生成器，各自独立产出对应物品链的 Lv1 物品。

## ADDED Requirements

### Requirement: GeneratorSystem supports per-instance generator_type

GeneratorSystem SHALL expose a `generator_type: String` property that determines which item type the generator produces. When `try_generate()` is called, the generated Lv1 item SHALL be of the type specified by `generator_type`. If `generator_type` is empty or unset, the generator SHALL default to producing `"drink"` items.

#### Scenario: Drink generator produces drink items

- **WHEN** a GeneratorSystem with `generator_type = "drink"` successfully generates
- **THEN** the created item has `type == "drink"` and `level == 1`

#### Scenario: Bread generator produces bread items

- **WHEN** a GeneratorSystem with `generator_type = "bread"` successfully generates
- **THEN** the created item has `type == "bread"` and `level == 1`

#### Scenario: Unset generator_type defaults to drink

- **WHEN** a GeneratorSystem with `generator_type = ""` successfully generates
- **THEN** the created item has `type == "drink"` and `level == 1`

### Requirement: ItemCellButton displays generator_type-specific icon

ItemCellButton SHALL support a `generator_type: String` export variable. When `is_generator = true` and `generator_type` is set, the GeneratorIcon TextureRect SHALL display the corresponding icon:
- `"drink"` → `res://sprites/art/咖啡机.png`
- `"bread"` → `res://sprites/art/烘焙机.png`

#### Scenario: Drink generator shows coffee machine icon

- **WHEN** an ItemCellButton has `is_generator = true` and `generator_type = "drink"`
- **THEN** the GeneratorIcon displays `res://sprites/art/咖啡机.png`

#### Scenario: Bread generator shows baking machine icon

- **WHEN** an ItemCellButton has `is_generator = true` and `generator_type = "bread"`
- **THEN** the GeneratorIcon displays `res://sprites/art/烘焙机.png`

### Requirement: GridBoard routes generator clicks to correct GeneratorSystem instance

GridBoard SHALL maintain a mapping from generator cell position to GeneratorSystem instance. When a generator cell is pressed, the board SHALL dispatch the `try_generate_from()` call to the GeneratorSystem instance associated with that cell's `generator_type`.

#### Scenario: Drink generator cell routes to drink GeneratorSystem

- **WHEN** a generator cell with `generator_type = "drink"` at position (col=3, row=8) is pressed
- **THEN** the GeneratorSystem with `generator_type = "drink"` is invoked to produce a drink item

#### Scenario: Bread generator cell routes to bread GeneratorSystem

- **WHEN** a generator cell with `generator_type = "bread"` at position (col=3, row=6) is pressed
- **THEN** the GeneratorSystem with `generator_type = "bread"` is invoked to produce a bread item
