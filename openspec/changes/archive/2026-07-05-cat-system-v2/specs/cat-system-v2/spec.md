## ADDED Requirements

### Requirement: CatSystem provides passive multiplier queries

CatSystem SHALL maintain an internal unlock status for 3 cats (`bread_cat`, `coffee_cat`, `engineer_cat`) and expose three query methods returning cumulative buff multipliers. All unlocked cats' buffs SHALL stack additively. The system SHALL NOT expose any cat selection or activation mechanism.

#### Scenario: Query production multiplier with all cats unlocked

- **WHEN** `CatSystem.get_production_multiplier()` is called and all 3 cats are unlocked
- **THEN** the system returns `1.10` (1.0 base + 0.10 from bread_cat)

#### Scenario: Query gold multiplier with all cats unlocked

- **WHEN** `CatSystem.get_gold_multiplier()` is called and all 3 cats are unlocked
- **THEN** the system returns `1.20` (1.0 base + 0.20 from coffee_cat)

#### Scenario: Query stamina regen multiplier with all cats unlocked

- **WHEN** `CatSystem.get_stamina_regen_multiplier()` is called and all 3 cats are unlocked
- **THEN** the system returns `1.25` (1.0 base + 0.25 from engineer_cat)

### Requirement: Cats are all unlocked by default in V1

In V1, CatSystem SHALL initialize all 3 cats as unlocked on startup without requiring any in-game progression. No persistence mechanism is required.

#### Scenario: All cats unlocked on game start

- **WHEN** CatSystem enters the scene tree and `_ready()` executes
- **THEN** the internal unlock dictionary SHALL contain `{bread_cat: true, coffee_cat: true, engineer_cat: true}`

### Requirement: CatSystem exposes unlock state for UI querying

CatSystem SHALL provide an `is_unlocked(cat_id: String) -> bool` method so UI components (e.g., cat collection page) can query individual cat availability.

#### Scenario: Query specific cat unlock status

- **WHEN** `CatSystem.is_unlocked("bread_cat")` is called
- **THEN** the system returns `true`
