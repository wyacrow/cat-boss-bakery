# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

《猫老板的面包店》(Cat Boss's Bakery) — a casual merge-2 + simulation management + cat raising game built with **Godot 4.7** (GDScript). The core loop: stamina → generator (inside grid) → grid (merge) → orders (direct from board) → rewards → cat upgrades → loop.

**Design principle**: Strictly separated, event-driven merge economy game. Prioritize clarity, modularity, and predictability — not over-engineering or complex architecture.

## Key Design Documents

- `cat_bakery_merge_design.md` — **设计文档**。frozen V1 system design：6 个核心系统 + 物品体系（3链×4级）+ 完整信号签名。**系统规则（合成逻辑、订单规则、数值公式）以此文件为准。**
- `cat_bakery_engineering_v1.md` — 工程架构文档：目录结构、系统摘要、EventBus 信号列表。
- `placeholder_asset_plan.md` — V1 临时占位素材方案。所有 UI/视觉工作需先参考此文件，后续切换 AI 素材的过渡策略。

**重要**：设计文档冻结于早期规划阶段，**场景文件（.tscn）和实际代码是布局/尺寸的最终权威**。当设计文档的数值（如格子数）与场景文件冲突时，**以场景文件为准**。系统规则（合成逻辑、订单公式等）仍以设计文档为准。

### 当前开发状态（调试期）

- **棋盘**：场景中为 **7×9 = 63 格**（非设计文档中的 6×6）
- **物品链**：`GeneratorSystem` 和 `OrderSystem` 中 `ITEM_TYPES = ["drink"]` — **debug 用**，仅生成饮品链物品
- **CatSystem**：代码已完成但**暂不连线**，非 MVP 第一要务
- **HUD**：StaminaBar/GoldDisplay 目前为纯色 ColorRect 占位，**数值绑定尚未实现**

## Godot Project Configuration

- **Engine version**: Godot 4.7
- **Renderer**: D3D12 (Windows) / Forward+
- **Physics**: Jolt Physics (3D)
- **Stretch mode**: `canvas_items` with `expand` aspect — UI is designed to scale.
- **Target resolution**: **1440×3120** (竖屏手机比例)

---

##  UI Layout Rules (CRITICAL - 从错误中学习)

> **错误清单**（按发生顺序）：
> 1. 假设分辨率是 1080×1920，实际是 1440×3120
> 2. 用锚点定位做垂直布局，应该用 VBoxContainer
> 3. 没有检查 project.godot 的窗口尺寸设置
> 4. 锚点和 offset 混用，导致子节点超出父容器
> 5. 尝试给容器节点直接设置 size（容器大小是自动计算的）
> 6. **ColorRect/TextureRect 子节点未设置锚点，导致大小为 0 无法显示**
>
> **根本原因**：假设多于确认，没有先检查基础参数就开始写代码
>
> **正确流程**：
> 1. 检查 `project.godot` → 确认窗口尺寸
> 2. 确认布局方向 → 垂直用 VBoxContainer，水平用 HBoxContainer
> 3. 确认比例关系 → 各区域的大小比例
> 4. 最后才写代码
>
> **Godot 布局系统规则**：
> - 容器节点（Container）的大小由子节点自动计算，**不能手动设置**
> - 锚点（anchor）和偏移（offset）**不要混用**，选一种即可
> - **Control 子节点（ColorRect/TextureRect）必须设置锚点才能正确显示**：
>   - `layout_mode = 1` (Use Anchor)
>   - `anchors_preset = 15` (Full Rect)
>   - `anchor_right = 1.0`, `anchor_bottom = 1.0`
>   - `grow_horizontal = 2`, `grow_vertical = 2`
> - 动手前必须先问清楚：分辨率？方向？比例？

### 本项目布局参数

- 目标分辨率：**1440×3120** (宽×高，竖屏手机) — 已设置于 `project.godot`
- 主布局容器：`VBoxContainer` (垂直排列)
- 三区比例：A:B:C = **2 : 4 : 1**

---

## Architecture

```
res://
├── scenes/          # .tscn scene files
├── scripts/
│   ├── systems/     # Gameplay systems (stamina, generator, grid, merge, orders, cats)
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
| **GeneratorSystem** | `GeneratorSystem.gd` | 棋盘内生成器格子触发→消耗1体力→随机Lv1物品投到最近空位 |
| **GridSystem** | `GridBoard.gd` | 动态行列棋盘，唯一合成场，**生成器位于棋盘内** |
| **MergeSystem** | `MergeSystem.gd` | Merging logic: 2× same LvN → 1× LvN+1; manual by default, auto-chain optional |
| **Collection** | ~~CollectSystem.gd~~ | **已移除**：订单直接从棋盘扣物品，无需收取系统 |
| **InventorySystem** | ~~InventorySystem.gd~~ | **已移除**：棋盘即缓冲区，无独立库存 |
| **OrderSystem** | `OrderSystem.gd` | 直接从棋盘校验+扣除物品，不经过库存 |
| **CatSystem** | `CatSystem.gd` | 全局数值 buff。V1 开局全解锁，buff 隐式叠加。面包猫（生产+10%）、咖啡猫（金币+20%）、工程猫（体力恢复+25%） |
| **Item** | `Item.gd` | 数据类（RefCounted）。`type: String` + `level: int`。放在 `scripts/data/` |

❌ Never mix responsibilities between systems.

---

# 🔁 2. DATA FLOW RULE (STRICT)

All gameplay data MUST flow in one direction:

```
Generator → Grid (merge/swap) → Order (direct consume)
```

❌ Forbidden:
- Order affecting Grid or Merge
- CatSystem modifying core rules or moving items

---

# 🧱 3. CODE STRUCTURE RULE

Each system must be:
- **ONE** script file
- **ONE** responsibility
- No hidden dependencies
- System-to-system direct method calls are **allowed** for synchronous queries/commands that need return values (e.g., `grid_board.has_items(req)`, `stamina.consume(1)`). See Rule 5 for guidelines.

Example file naming:
- `GridBoard.gd`
- `MergeSystem.gd`
- `GeneratorSystem.gd`

---

# 🧠 4. DATA HANDLING RULES

## Grid
- 动态行列数（从 GridContainer 读取 columns + cell 数量）
- 每个格子是一个 Button，支持按下/弹起动画
- Store only data (`Item` or `null`) in the array
- 订单直接扫描棋盘扣物品（`has_items` / `remove_items`）

## Items
- Must have at minimum:
  - `type: String` — `"bread"` | `"dessert"` | `"drink"`
  - `level: int` — 1~4
- Defined as `Item` class (extends `RefCounted`), not a plain dictionary
- 3 chains × 4 levels = 12 total items, see `cat_bakery_merge_design.md` §三 for full chain

---

# 🔁 5. COMMUNICATION RULE

Two mechanisms, each with a distinct role. Don't confuse them.

## EventBus — 全局广播（一对多，纯通知）

Use EventBus signals for:

| 类别 | 场景 | 示例 |
|---|---|---|
| 状态变更广播 | 某个值变了，UI/其他系统需要知道 | `stamina_changed`, `gold_changed` |
| 领域事件 | "发生了什么事"，监听方自行决定如何响应 | `order_completed`, `merge_done`, `order_generated` |
| 回调缺失 | 异步操作的结果通知（如资源加载完成） | 谨慎使用，多数情况直接调用更清晰 |

EventBus 信号的特点：
- **fire-and-forget**：emit 方不关心谁在听、有几个在听
- **无返回值**：信号不是函数调用，不能 return true/false
- **emit 方不依赖 listener 是否存在**

❌ 不要用 EventBus 模拟同步请求-响应。如果调用方需要立即知道结果，用直接调用。

## 直接方法调用 — 同步查询/命令（一对一，需返回值）

以下场景使用直接调用：

| 场景 | 示例 |
|---|---|
| 查询数据 | `grid_board.has_items(req)` → bool |
| 同步命令 | `stamina.consume(1)` → bool |
| 校验操作 | `order_system.submit_order(id)` → bool |
| UI 触发系统 | 按钮点击 → 直接调系统方法 |

```
系统 A ──→ 系统 B.some_method(args) ──→ return value
```

方法调用成功后，被调方通过 EventBus 广播状态变更，让 UI 和其他系统响应。

## 判断原则

```
需要返回值/立即知道结果？ → 直接调用
只是通知"某件事发生了"？  → EventBus
```

## UI 规则

- **UI 可以调用系统方法**（如点击提交按钮 → `order_system.submit_order()`）
- **UI 不要调用其他 UI 的方法** — 用 EventBus 或上级容器协调
- **UI 通过监听 EventBus 来刷新显示**

Required EventBus signals (full signatures defined in `cat_bakery_merge_design.md` §四):
- `stamina_changed(current: int, max_stamina: int)`
- `grid_changed(positions: Array[Vector2i])`
- `merge_done(from_pos: Vector2i, to_pos: Vector2i, result_item: Item)`
- `order_completed(order_id: String, reward_gold: int)`
- `order_generated(order: OrderData)`
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

# 📋 8. ORDER RULE

- Orders only consume Grid items
- Orders validate & remove items directly from board

---

# 🔋 9. GENERATOR RULE

- 生成器位于棋盘内（是棋盘的一个特殊格子，不是外部按钮）
- 点击生成器格 → 消耗 1 体力 → 随机 Lv1 物品 → 投到曼哈顿距离最近空位
- 三链等概率（33/33/33 bread/dessert/drink）
- GeneratorSystem 为 RefCounted，由 GridBoard 持有并调用

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
- Don't use EventBus signals for synchronous request-response — use direct method calls instead
- Don't put game logic outside systems/ directory
- Don't hard-couple systems
- Don't embed UI logic inside systems
- Don't mix data + view logic
- Don't use EventBus signals for synchronous request-response — use direct method calls instead

---

# 🎯 12. OUTPUT RULES

When generating code:
- Keep files independent
- One system per script
- Direct calls for queries/commands that need return values; EventBus for state change broadcasts
- Keep logic minimal and readable

---

## Development Commands

- **Run the project**: Open `project.godot` in the Godot 4.7 editor and press F5, or run `godot --path .` from the project root.
- **Run a specific scene**: `godot --path . path/to/scene.tscn`
- **Headless run** (for CI): `godot --path . --headless --quit`

## OpenSpec

This project uses spec-driven development via OpenSpec. Config is in `openspec/config.yaml`. The `.claude/commands/opsx/` directory contains slash commands for proposing, applying, exploring, archiving, and syncing changes.
