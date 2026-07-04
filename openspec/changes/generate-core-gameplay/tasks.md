## 1. Project Bootstrap (Phase 0)

- [ ] 1.1 Register EventBus and PlayerData as Autoloads in `project.godot` — add `[autoload]` section with `EventBus="*res://scripts/core/EventBus.gd"` and `PlayerData="*res://scripts/core/PlayerData.gd"`
- [ ] 1.2 Create directory structure: `scripts/core/`, `scripts/data/`, `scripts/systems/`, `scripts/views/`, `scenes/`

## 2. Core Infrastructure (Phase 1)

- [ ] 2.1 Create `scripts/core/EventBus.gd` — Autoload singleton extending Node, 11 signals with exact signatures from design doc
- [ ] 2.2 Create `scripts/core/PlayerData.gd` — Autoload singleton extending Node, holds `gold: int`, provides `add_gold()`/`spend_gold()`/`get_gold()`, listens to `order_completed` to credit gold, emits `gold_changed`
- [ ] 2.3 Create `scripts/data/Item.gd` — RefCounted data class with `type: String`, `level: int`, `get_display_name()`, `get_key()`, `can_merge_with()`, `get_merge_result()`
- [ ] 2.4 Create `scenes/main.tscn` — Root scene with `Node2D` named "Main", attach placeholder script

## 3. Game Systems (Phase 2)

- [ ] 3.1 Create `scripts/systems/StaminaSystem.gd` — max 20, 30s recovery, `consume()`/`recover()`, cat buff multiplier, emits `stamina_changed`
- [ ] 3.2 Create `scripts/systems/GridBoard.gd` — 6×6 Array[Array], `get_item()`/`place_item()`/`remove_item()`/`find_empty()`/`is_full()`, listens to `collect_done` to remove collected items from grid, emits `grid_changed`
- [ ] 3.3 Create `scripts/systems/GeneratorSystem.gd` — `try_generate() -> int` (returns 0/1/2 for success/no_stamina/grid_full), consumes 1 stamina → spawns 1 Lv1 item (33/33/33 random), auto-places to grid, connects to StaminaSystem and GridBoard via EventBus
- [ ] 3.4 Create `scripts/systems/MergeSystem.gd` — manual merge (select A → select B → merge if compatible), auto-merge toggle (scan on `grid_changed`, 0.1s chain timer), emits `merge_done` and `auto_merge_toggled`
- [ ] 3.5 Create `scripts/systems/CollectSystem.gd` — triple-tap detector (0.8s window, 50% radius tolerance), priority over merge selection, emits `collect_request`
- [ ] 3.6 Create `scripts/systems/InventorySystem.gd` — Dictionary storage, capacity 25, `add_item()`/`remove_items()`/`has_items()`/`get_count()`, handles `collect_request` → `collect_done`/`collect_failed`, emits `inventory_changed`
- [ ] 3.7 Create `scripts/systems/OrderSystem.gd` — 3 slots, 60s Timer auto-generate, Lv2+ only, 1-2 types × 1-3 qty, `submit_order()` validates against InventorySystem, cat gold multiplier, emits `order_generated`/`order_completed`/`gold_changed`
- [ ] 3.8 Create `scripts/systems/CatSystem.gd` — 3 cats (bread_cat/coffee_cat/engineer_cat), unlock conditions, `active_cat` switching, buff query methods, emits unlock notifications

## 4. UI Views (Phase 3)

- [ ] 4.1 Create `scripts/views/GridView.gd` — Control node, renders 6×6 grid via `_draw()` using StyleBoxFlat (64×64 cells + 4px gap), handles `_gui_input()` for tap events, listens to `grid_changed` → `queue_redraw()`
- [ ] 4.2 Create `scripts/views/ItemView.gd` — Control node, renders single item: type-color background (bread=#F4A460, dessert=#F8B0C2, drink=#8B6F47), emoji symbol, level badge, golden border for Lv4
- [ ] 4.3 Create `scripts/views/HudPanel.gd` — Top bar (cat avatar + stamina ProgressBar + gold Label), Generate button below grid, listens to `stamina_changed`/`gold_changed`
- [ ] 4.4 Create `scripts/views/CatView.gd` — 48×48 circle + emoji face via `_draw()`, golden glow on active, handles click for cat switch
- [ ] 4.5 Create `scripts/views/InventoryPanel.gd` — Scrollable grid rendering inventory Dictionary, 48×48 slots, title "📦 库存 (N/25)", listens to `inventory_changed`
- [ ] 4.6 Create `scripts/views/OrderPanel.gd` — 3 order cards vertically, shows requirements (item icons + counts) + reward, submit button per card, listens to `order_generated`/`order_completed`

## 5. Integration & Scene Assembly (Phase 4)

- [ ] 5.1 Add all 8 system nodes as children of Main scene root via `mcp__godot__add_node`
- [ ] 5.2 Add all 6 view nodes as children of Main scene UI container
- [ ] 5.3 Wire all signals in Main._ready() — connect system-to-system and system-to-UI signals
- [ ] 5.4 Set up mobile UI layout: TopBar (56px) → GridArea (centered, 408×408px, auto-merge toggle at bottom-right corner) → GenerateButton (56px) → BottomSection (InventoryPanel 60% + OrderPanel 40%)
- [ ] 5.5 Save final scene via `mcp__godot__save_scene`

## 6. Verification (Phase 5)

- [ ] 6.1 Run project via `mcp__godot__run_project` and verify all 8 system init messages in debug output
- [ ] 6.2 Test core loop: Generate → Merge → Collect → Submit Order — verify all signals fire correctly
- [ ] 6.3 Test edge cases: grid full, inventory full, insufficient stamina, auto-merge chain, cat switch
- [ ] 6.4 Verify mobile layout on different aspect ratios via `canvas_items + expand` stretch mode