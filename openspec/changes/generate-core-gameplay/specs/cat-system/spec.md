## ADDED Requirements

### Requirement: Three cats with unique buffs
The CatSystem SHALL define exactly 3 cats, each with a unique buff and unlock condition:

| Cat | Buff | Unlock |
|---|---|---|
| 面包猫 (Bread Cat) | 面包线合成经验 +10%（V1 预留接口，无实际消费者） | Default |
| 咖啡猫 (Coffee Cat) | 订单金币 +20% | Complete 5 orders |
| 工程猫 (Engineer Cat) | 体力恢复速度 +25% | Inventory full once |

#### Scenario: Default cat available
- **WHEN** the game starts
- **THEN** 面包猫 is unlocked and active

### Requirement: Only one cat active at a time
The CatSystem SHALL allow only one cat to be active at any time. The `active_cat: String` field SHALL store the currently active cat's name.

#### Scenario: Switch active cat
- **WHEN** player switches from 面包猫 to 咖啡猫 (if unlocked)
- **THEN** `active_cat` changes to "coffee_cat" and the previous cat's buffs are deactivated

### Requirement: Cat unlock conditions
The CatSystem SHALL listen to `EventBus.order_completed` to track completed orders and `EventBus.inventory_changed` to detect inventory full state.

#### Scenario: Unlock coffee cat
- **WHEN** the 5th order is completed
- **THEN** 咖啡猫 becomes unlocked and available for switching

#### Scenario: Unlock engineer cat
- **WHEN** inventory reaches capacity (25 items) for the first time
- **THEN** 工程猫 becomes unlocked and available for switching

### Requirement: Cat switch with no cost
The CatSystem SHALL allow switching between unlocked cats at any time with no cost or cooldown.

#### Scenario: Switch cats freely
- **WHEN** player taps a different unlocked cat
- **THEN** the active cat switches immediately

### Requirement: Buff query methods
The CatSystem SHALL provide query methods for other systems to retrieve current buff multipliers:
- `get_gold_multiplier() -> float` (default 1.0, coffee cat 1.2)
- `get_stamina_regen_multiplier() -> float` (default 1.0, engineer cat 1.25)
- `get_bread_exp_multiplier() -> float` (default 1.0, bread cat 1.1) — **V1 reserved interface: no system consumes this multiplier in V1. Reserved for future merge-experience mechanic.**

#### Scenario: Query buff values
- **WHEN** `get_gold_multiplier()` is called with coffee cat active
- **THEN** the method returns `1.2`

### Requirement: Cats provide only numeric buffs
The CatSystem SHALL only provide numeric buff multipliers. It SHALL NOT modify core game rules, move items, trigger merges, or interact with gameplay logic.

#### Scenario: Buff is passive
- **WHEN** any cat buff is active
- **THEN** only numeric values are modified; no gameplay rules change

### Requirement: V1 no leveling or upgrades
The CatSystem SHALL NOT implement cat levels, experience, or upgrade mechanics in V1. Cats have fixed buffs that do not change.

#### Scenario: Fixed buffs
- **WHEN** a cat is unlocked
- **THEN** its buff value is fixed and never changes