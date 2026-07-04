# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

《猫老板的面包店》(Cat Boss's Bakery) — a casual merge-2 + simulation management + cat raising game built with **Godot 4.7** (GDScript). The core loop: stamina → generator → grid (merge) → collect → inventory → orders → rewards → cat upgrades → loop.

**Design principle**: Strictly separated, event-driven merge economy game. Prioritize clarity, modularity, and predictability — not over-engineering or complex architecture.

## Key Design Documents

- `cat_bakery_merge_design.md` — **权威设计文档**。frozen V1 system design：8 个核心系统 + 物品体系（3链×4级）+ 完整信号签名 + 7 项补全决策。所有系统规则以此文件为准。
- `cat_bakery_engineering_v1.md` — 工程架构文档：目录结构、系统摘要、EventBus 信号列表。
- `placeholder_asset_plan.md` — V1 临时占位素材方案。所有 UI/视觉工作需先参考此文件，后续切换 AI 素材的过渡策略。

Always consult these docs before implementing any game system — they are the authoritative spec.

## Godot Project Configuration

- **Engine version**: Godot 4.7
- **Renderer**: D3D12 (Windows) / Forward+
- **Physics**: Jolt Physics (3D)
- **Stretch mode**: `canvas_items` with `expand` aspect — UI is designed to scale.

## Architecture

```
res://
├── scenes/          # .tscn scene files
├── scripts/
│   ├── systems/     # Gameplay systems (stamina, grid, merge, inventory, orders, cats)
│   ├── data/        # Data definitions, item types, levels, recipes
│   └── core/        # Core infrastructure (EventBus, global state, etc.)
└── assets/          # Sprites, audio, etc.
```

---

# 🚨 1. ARCHITECTURE RULE (MOST IMPORTANT)

You MUST strictly separate systems. Each system gets **one script file, one responsibility, no hidden dependencies**.

| System | Script | Responsibility |
|---|---|---|
| **StaminaSystem** | `StaminaSystem.gd` | Max 20, recovers 1/30s, consumed by generators |
| **GeneratorSystem** | `GeneratorSystem.gd` | Consumes 1 stamina → spawns 1 **Lv1 item only**, places into Grid |
| **GridSystem** | `GridBoard.gd` | 6×6 tile/item placement, the **only** place merging happens |
| **MergeSystem** | `MergeSystem.gd` | Merging logic: 2× same LvN → 1× LvN+1; manual by default, auto-chain optional |
| **Collection** | `CollectSystem.gd` | 三击收取（0.8s 内点同一物品 3 次），grid → inventory（单向） |
| **InventorySystem** | `InventorySystem.gd` | Storage only — no merging, no gameplay logic, no return to grid |
| **OrderSystem** | `OrderSystem.gd` | Consumes inventory items, rewards gold; must NOT interact with Grid |
| **CatSystem** | `CatSystem.gd` | 全局数值 buff。3 只猫，同时激活 1 只。面包猫（默认，生产+10%）、咖啡猫（完成5订单解锁，金币+20%）、工程猫（库存满1次解锁，体力恢复+25%）。V1 无等级无升级 |
| **Item** | `Item.gd` | 数据类（RefCounted）。`type: String` + `level: int`。放在 `scripts/data/` |

❌ Never mix responsibilities between systems.

---

# 🔁 2. DATA FLOW RULE (STRICT)

All gameplay data MUST flow in one direction:

```
Generator → Grid → Merge → Collect → Inventory → Order
```

❌ Forbidden:
- Inventory → Grid (no回流)
- Inventory → Merge
- Order affecting Grid or Merge
- CatSystem modifying core rules or moving items

---

# 🧱 3. CODE STRUCTURE RULE

Each system must be:
- **ONE** script file
- **ONE** responsibility
- No hidden dependencies
- No cross-system direct method calls — use signals/EventBus

Example file naming:
- `GridBoard.gd`
- `MergeSystem.gd`
- `InventorySystem.gd`

---

# 🧠 4. DATA HANDLING RULES

## Grid
- Must use `Array[6][6]`
- **NO node-per-cell design** — data-driven only
- Store only data (`Item` or `null`)

## Inventory
- Must use `Dictionary`
- Key format: `"type_level"` (string)
- Must support capacity limit: **25**

## Items
- Must have at minimum:
  - `type: String` — `"bread"` | `"dessert"` | `"drink"`
  - `level: int` — 1~4
- Defined as `Item` class (extends `RefCounted`), not a plain dictionary
- 3 chains × 4 levels = 12 total items, see `cat_bakery_merge_design.md` §三 for full chain

---

# 🔁 5. SIGNAL / EVENT RULE

All communication MUST use signals or EventBus. **UI must NOT call system logic directly.**

Required signals (full signatures defined in `cat_bakery_merge_design.md` §四):
- `stamina_changed(current: int, max_stamina: int)`
- `grid_changed(positions: Array[Vector2i])`
- `merge_done(from_pos: Vector2i, to_pos: Vector2i, result_item: Item)`
- `inventory_changed(added_items: Array[Item], removed_items: Array[Item])`
- `order_completed(order_id: String, reward_gold: int)`
- `order_generated(order_id: String, requirements: Dictionary)`
- `collect_request(item: Item, from_pos: Vector2i)`
- `collect_done(item: Item)`
- `collect_failed(reason: String)`
- `auto_merge_toggled(enabled: bool)`
- `gold_changed(current: int)`

---

# 🎮 6. MERGE RULE

- Only 2 same items can merge
- `type` AND `level` must both match
- Result: `level + 1`
- **Lv4 is max level** — Lv4 + Lv4 does not merge
- No random or special merge logic in V1
- Auto-merge mode must be manually toggled on (off by default)

---

# 📦 7. INVENTORY RULE

- Inventory is **storage only**
- No merging inside inventory
- No gameplay logic inside inventory
- Items enter inventory **only** from Grid collection (one-way)

---

# 📋 8. ORDER RULE

- Orders only consume Inventory
- Orders must NOT interact with Grid
- Orders only validate & subtract items

---

# 🔋 9. GENERATOR RULE

- Generates **ONLY Lv1 items**
- Must consume stamina (1 stamina = 1 item)
- Must place items into Grid only

---

# 🐱 10. CAT SYSTEM RULE

- Only provides **numeric buffs**
- Cannot modify gameplay logic
- Cannot move items or trigger merges
- Only modifies values like:
  - stamina regen rate
  - generation speed
  - order reward multiplier

---

# ⚙️ 11. GODOT IMPLEMENTATION RULES

## DO:
- Use GDScript
- Use `snake_case` for functions/variables
- Use signals for communication
- Use arrays/dictionaries for data systems
- Keep scripts modular and small
- Separate data logic from view logic

## DON'T:
- Don't create node-per-grid-cell
- Don't hard-couple systems
- Don't embed UI logic inside systems
- Don't mix data + view logic
- Don't allow cross-system direct method calls

---

# 🎯 12. OUTPUT RULES

When generating code:
- Keep files independent
- One system per script
- Avoid cross-system references
- Prefer signals over direct calls
- Keep logic minimal and readable

---

## Development Commands

- **Run the project**: Open `project.godot` in the Godot 4.7 editor and press F5, or run `godot --path .` from the project root.
- **Run a specific scene**: `godot --path . path/to/scene.tscn`
- **Headless run** (for CI): `godot --path . --headless --quit`

## OpenSpec

This project uses spec-driven development via OpenSpec. Config is in `openspec/config.yaml`. The `.claude/commands/opsx/` directory contains slash commands for proposing, applying, exploring, archiving, and syncing changes.
