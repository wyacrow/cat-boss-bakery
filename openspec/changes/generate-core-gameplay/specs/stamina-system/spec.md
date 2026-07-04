## ADDED Requirements

### Requirement: Stamina maximum capacity
The StaminaSystem SHALL maintain a `max_stamina` value of 20, configurable via `@export var max_stamina: int = 20`.

#### Scenario: Initial stamina
- **WHEN** the game starts
- **THEN** `current_stamina` equals `max_stamina` (20)

### Requirement: Stamina recovery rate
The StaminaSystem SHALL recover 1 stamina point every 30 seconds when `current_stamina` is less than `max_stamina`.

#### Scenario: Automatic recovery
- **WHEN** `current_stamina` is 15 and 30 seconds pass
- **THEN** `current_stamina` becomes 16 and `stamina_changed(16, 20)` is emitted

#### Scenario: Recovery stops at max
- **WHEN** `current_stamina` is 20
- **THEN** no further recovery occurs

### Requirement: Stamina consumption
The StaminaSystem SHALL provide a `consume(amount: int) -> bool` method that returns `true` if sufficient stamina exists, and `false` otherwise.

#### Scenario: Successful consumption
- **WHEN** `consume(1)` is called with `current_stamina` = 15
- **THEN** `current_stamina` becomes 14, `stamina_changed(14, 20)` is emitted, and the method returns `true`

#### Scenario: Insufficient stamina
- **WHEN** `consume(1)` is called with `current_stamina` = 0
- **THEN** `current_stamina` remains 0, no signal is emitted, and the method returns `false`

### Requirement: Stamina recovery
The StaminaSystem SHALL provide a `recover(amount: int)` method that increases stamina up to `max_stamina`.

#### Scenario: Partial recovery
- **WHEN** `recover(2)` is called with `current_stamina` = 10
- **THEN** `current_stamina` becomes 12 and `stamina_changed(12, 20)` is emitted

### Requirement: Cat buff modifies recovery rate
The StaminaSystem SHALL support a `regen_multiplier: float` that modifies the base recovery rate. When CatSystem sets the multiplier to 1.25, recovery SHALL be 1 point every 24 seconds.

#### Scenario: Engineer cat buff active
- **WHEN** engineer cat is active (multiplier = 1.25)
- **THEN** stamina recovery interval is 24 seconds instead of 30

### Requirement: Stamina changed signal emission
The StaminaSystem SHALL emit `EventBus.stamina_changed(current, max_stamina)` every time `current_stamina` changes.

#### Scenario: Signal on every change
- **WHEN** `current_stamina` changes from any source (consume, recover, or initialization)
- **THEN** `stamina_changed` signal is emitted with the new values