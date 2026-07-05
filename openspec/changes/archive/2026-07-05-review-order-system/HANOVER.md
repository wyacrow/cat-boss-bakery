# 订单系统 — 工作交接文档

> **日期**: 2026-07-05 | **状态**: 架构完成，待功能集成

---

## 一、做了什么

### 1.1 新建文件

| 文件 | 说明 |
|---|---|
| [scripts/ui/components/order_bar_manager.gd](../../scripts/ui/components/order_bar_manager.gd) | 订单栏视觉管理器，负责 OrderSlot 的创建/销毁/定位/位移动画 |

**OrderBarManager 核心功能**:
- 3 个锚定位置（`Vector2(0,38) → (470,38) → (940,38)`），slot 大小 500×400
- 监听 `EventBus.order_generated` → 错开 0.08s 依次创建 OrderSlot（出场淡入动画）
- 监听 `EventBus.order_completed` → 对应 slot 播放退场动画 → 销毁 → 剩余 slot 左移动画
- 使用 `_pending_orders` 队列 + `await` 避免批量 emit 时动画重叠
- 所有动画参数可调：`appear_duration` / `disappear_duration` / `shift_duration` / `stagger_delay`

### 1.2 修改文件

| 文件 | 改动内容 |
|---|---|
| [scripts/ui/components/order_slot.gd](../../scripts/ui/components/order_slot.gd) | 新增 `disappear_finished` 信号 + 3 个动画方法；`_cache_children` 适配原始 scene 节点名；`_update_requirements` 按物品数量自适应图标大小 |
| [scripts/systems/OrderSystem.gd](../../scripts/systems/OrderSystem.gd) | `_generate_initial_orders()` 改用 `call_deferred`，延迟一帧等 GameScene 连线完成 |
| [scripts/core/GameScene.gd](../../scripts/core/GameScene.gd) | 新增 `_wire_order_system()` 方法，连线 OrderSystem → GridBoard → OrderBarManager |
| [scenes/GameScene.tscn](../../scenes/GameScene.tscn) | 删除静态 OrderSlot_2/3 节点；新增 OrderSystem 节点（Node 类型，挂载 OrderSystem.gd） |
| [scenes/ui/order_slot.tscn](../../scenes/ui/order_slot.tscn) | 保持原始布局不变，新增 AnimationPlayer 子节点（占位） |

### 1.3 新增动画方法（order_slot.gd）

```
animate_appear(0.2s)     modulate: 透明→不透明 + scale: 0.85→1.0   TRANS_QUAD EASE_OUT
animate_disappear(0.25s)  modulate: 不透明→透明 + scale: 1.0→0.85   TRANS_QUAD EASE_IN，完成后 emit disappear_finished
animate_to_position(0.3s) position: 当前→目标                       TRANS_QUAD EASE_IN_OUT
```

### 1.4 运行时连线（GameScene._ready 调用顺序）

```
GameScene._ready()
  ├── apply_cell_button_size()
  ├── wire_stamina_and_generator()     ← StaminaSystem → GridBoard
  └── wire_order_system()
        ├── $OrderSystem.set_grid_board(grid)
        ├── OrderBar.set_script(order_bar_manager.gd)   ← 动态挂载
        └── OrderBar.setup(order_sys)                   ← 连接 EventBus

OrderSystem._ready()
  └── timer 启动 + call_deferred("_generate_initial_orders")
       → 延迟到下一帧 emit order_generated ×3
          → OrderBarManager 接收 → 按序创建 3 个 OrderSlot（错开动画）
```

### 1.5 已验证

- ✅ 项目启动零错误
- ✅ 3 个订单卡依次出现在 3 个锚定位置
- ✅ 物品图标自适应大小（单物品 120px / 双物品 80px）
- ✅ 动画参数可导出处编辑

---

## 二、没做什么（待后续开发）

### 2.1 功能缺口

| 待完成 | 说明 | 优先级 |
|---|---|---|
| **订单提交闭环** | GridBoard 已有 `has_items()`/`remove_items()`，但棋盘上目前无物品可提交。需先实现 GeneratorSystem 产出物品到棋盘 | 🔴 阻塞 |
| **提交动画** | AnimationPlayer 已挂载但从未调用。`submit_order` 成功后可触发完成动画 | 🟡 中 |
| **猫咪 Buff 集成** | OrderSystem 有 `cat_gold_multiplier` 和 `set_cat_gold_multiplier()`，CatSystem 未调用 | 🟡 中 |
| **库存系统** | 设计文档提到 InventorySystem，但 V1 改从棋盘直接扣物品（OrderSystem 使用 grid_board 接口）。库存后续可能回归 | 🟢 低 |
| **UI 纹理** | 所有 customer cat / item 纹理指向同一占位图（cat.png / food.png / cake.png） | 🟢 低 |
| **order_slot.tscn UID** | `rewardbtn.png` 的 UID (`uid://b3fovdnwchqy1`) 在 git 之外生成，collaborator 首次打开需 Godot 编辑器重新导入 | 🟢 低 |
| **order_bar_manager.gd.uid** | 缺少 .uid 文件，首次在编辑器中打开即会生成 | 🟢 低 |

### 2.2 设计决策备注

- **OrderSystem 不是 Autoload**，是 GameScene 中的一个 Node 子节点（与 StaminaSystem 同级）
- **订单直接从棋盘扣物品**（NOT 从库存），通过 `grid_board.has_items()` / `remove_items()` 接口
- **OrderBarManager 和 OrderSystem 通过 EventBus 解耦**：Manager 只监听事件，不直接调用 OrderSystem
- **`generation_interval = 6.0`** 是调试值；生产环境应改为 60s（规格见 `cat_bakery_merge_design.md` §7）

---

## 三、系统架构总览

```
┌─────────────────────────────────────────────────────────┐
│  GameScene (Control, @tool)                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │ MainVBox (VBoxContainer)                          │  │
│  │ ┌─────────────────────────────────────────────┐   │  │
│  │ │ AreaA_Top (891px)                            │   │  │
│  │ │ ┌──────────────────────┐ ┌────────────────┐  │   │  │
│  │ │ │ TopHUDBar             │ │ OrderBar       │  │   │  │
│  │ │ │ (体力/金币/设置)      │ │ [OrderBarMgr]  │  │   │  │
│  │ │ └──────────────────────┘ │  ├─ OrderSlot 0  │  │   │  │
│  │ │                          │  ├─ OrderSlot 1  │  │   │  │
│  │ │                          │  └─ OrderSlot 2  │  │   │  │
│  │ │                          └────────────────┘  │   │  │
│  │ └─────────────────────────────────────────────┘   │  │
│  │ ┌─────────────────────────────────────────────┐   │  │
│  │ │ AreaB_Grid (1783px)                          │   │  │
│  │ │ ┌─────────────────────────────────────────┐  │   │  │
│  │ │ │ GridBoard (PanelContainer)               │  │   │  │
│  │ │ │  ├─ MergeSystem                          │  │   │  │
│  │ │ │  ├─ GeneratorSystem ← StaminaSystem      │  │   │  │
│  │ │ │  └─ GridContainer (7×? cells)            │  │   │  │
│  │ │ └─────────────────────────────────────────┘  │   │  │
│  │ └─────────────────────────────────────────────┘   │  │
│  │ ┌─────────────────────────────────────────────┐   │  │
│  │ │ AreaC_Bottom (446px)                         │   │  │
│  │ │ (生成按钮 / 物品详情 / 自动合成开关)         │   │  │
│  │ └─────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ OrderSystem (Node)                                 │  │
│  │  - _orders[3]: OrderData|null                       │  │
│  │  - grid_board → GridBoard.has_items/remove_items   │  │
│  │  - Timer: 每 6s 生成新订单                         │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ StaminaSystem (Node)                               │  │
│  │  - stamina: 20/20, 恢复 1/30s                      │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

Autoloads:
  EventBus  — 全局信号：order_generated, order_completed, ...
  GameStat  — 全局状态：gold, 监听 order_completed 加金币
```

### 数据流

```
GeneratorSystem → GridBoard (棋盘) → OrderSystem.submit_order()
  ├── has_items(req)  ← 校验
  └── remove_items(req) ← 扣除

OrderSystem
  ├── emit order_generated(order)  →  OrderBarManager._create_slot()
  └── emit order_completed(id, gold) → GameStat._on_order_completed()
                                     → OrderBarManager._on_order_completed()
```

---

## 四、如何继续开发

### 4.1 最小可玩流程（下一步）

1. **让棋盘上有物品**：在 AreaC 点击生成按钮 → 消耗 Stamina → GridBoard 上放置 Lv1 物品
2. **合成升级**：GridBoard 已实现合并逻辑（MergeSystem），拖拽两个相同物品合并
3. **提交订单**：棋盘上有足够高阶物品后，点击 OrderSlot → `submit_order()` → 物品扣除，金币增加
4. **观察动画**：提交成功后卡片消失 + 剩余卡片左移

### 4.2 调试技巧

- 将 `generation_interval` 设为 `6.0`（当前值）快速观察订单生成
- 调用 `OrderSystem.cancel_order(id)` 手动清空槽位
- 调用 `OrderSystem.set_cat_gold_multiplier(1.2)` 模拟咖啡猫 buff
- 所有 `@export` 参数可在编辑器中直接调

### 4.3 接入新系统时的注意事项

- 需要在 **GameScene._ready()** 中注入依赖（参照 `_wire_order_system()` 模式）
- **不要**创建额外的 EventBus 信号来模拟同步请求—用直接方法调用
- OrderSlot 的 `set_order_system()` 和 OrderSystem 的 `set_grid_board()` 都是注入式接口

---

## 五、已知问题（非阻塞）

1. `GridBoard.gd:92` — Integer division warning（预存）
2. 多个文件的 `const ResourceDB := preload(...)` 与 global class 重名 warning（项目惯例，可忽略）
3. `rewardbtn.png` 的 UID 可能在他人机器上失效 → 首次打开 Godot 编辑器自动修复
4. `_update_visual()` 缩进异常（双 tab），不影响运行
