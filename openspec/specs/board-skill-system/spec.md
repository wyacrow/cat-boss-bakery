# Board Skill System

## Purpose

棋盘技能框架 — 提供操纵棋盘格子的原子操作层和技能管理层，支持通过组合原子操作实现复杂技能。所有技能通过 Callable 注入执行逻辑，动画为纯视觉覆盖层（数据先更新，动画后播放）。框架与猫咪系统解耦，猫咪激活时注册对应技能即可。

## Requirements

### Requirement: BoardSkill 数据类封装技能元数据和执行逻辑

BoardSkill（RefCounted）SHALL 包含 `skill_id`、`display_name`、`description`、`cooldown`（秒）和一个 Callable `_execute`。Callable 签名为 `func(BoardSkillSystem, GridBoard) -> Array[Vector2i]`，返回受影响的格子位置列表。

#### Scenario: 创建洗牌技能实例

- **WHEN** `BoardSkill.new("shuffle", "猫咪shuffle", "重新随机排列...", 3.0, execute_func)` 被调用
- **THEN** 返回的 BoardSkill 实例包含 skill_id="shuffle"、cooldown=3.0、execute 指向 execute_func

#### Scenario: 执行技能 Callable

- **WHEN** `skill.execute(system, board)` 被调用且 `_execute` Callable 有效
- **THEN** Callable 被执行，接收 system 和 board 两个参数，返回操作影响的格子位置列表

---

### Requirement: BoardSkillSystem 管理技能注册、冷却和触发

BoardSkillSystem（Node）SHALL 通过 `register_skill(skill)` 注册技能，通过 `use_skill(skill_id)` 触发技能。触发时检查顺序为：board 就绪 → 技能存在 → 冷却就绪 → execute → 启动冷却 → emit `grid_changed`。

#### Scenario: 注册并触发技能

- **WHEN** `register_skill(shuffle_skill)` 后调用 `use_skill("shuffle")`
- **THEN** 若冷却就绪，execute Callable 被调用，返回非空时冷却启动且 `EventBus.grid_changed` 被 emit

#### Scenario: 冷却中触发被拒绝

- **WHEN** 技能冷却剩余 2.0s 时调用 `use_skill("shuffle")`
- **THEN** 方法返回 false，execute 不被调用，打印冷却提示

#### Scenario: 未 setup 时触发报错

- **WHEN** `use_skill` 在 `setup(board)` 之前被调用
- **THEN** 方法返回 false，`push_error` 被调用

---

### Requirement: 原子操作 — 单格行为

BoardSkillSystem SHALL 提供以下单格原子操作，每个操作同时更新 `grid_data` 和 cell UI，失败（条件不满足）返回空数组 `[]`：

| 方法 | 效果 | 前提条件 |
|---|---|---|
| `cell_upgrade(pos)` | 物品等级+1（免费合成） | 格子非空，物品未达 Lv4 |
| `cell_remove(pos)` | 清除物品 | 格子非空，非生成器 |
| `cell_place(pos, item)` | 放置已有 Item | 格子为空，非生成器 |
| `cell_place_new(pos, type, level)` | 创建并放置 Item | 格子为空，非生成器 |
| `cell_transform(pos, new_type)` | 改变物品类型（保持等级） | 格子非空，type 不同 |

#### Scenario: 升级 Lv2 物品

- **WHEN** pos (0,0) 有 drink Lv2 物品，调用 `cell_upgrade(Vector2i(0,0))`
- **THEN** grid_data 和 cell 均更新为 drink Lv3，cell 播放 `play_release_animation`，返回 `[pos]`

#### Scenario: 升级 Lv4 物品被拒绝

- **WHEN** pos (0,0) 有 drink Lv4 物品，调用 `cell_upgrade(Vector2i(0,0))`
- **THEN** 返回 `[]`，数据不变

#### Scenario: 在空格放置物品

- **WHEN** pos (1,0) 为空，调用 `cell_place_new(Vector2i(1,0), "drink", 1)`
- **THEN** 创建 drink Lv1 并放置到 (1,0)，cell 更新并弹跳，返回 `[pos]`

#### Scenario: 在生成器格操作被拒绝

- **WHEN** 任何原子操作的目标格为生成器（`cell.is_generator == true`）
- **THEN** 操作失败，返回 `[]`

---

### Requirement: 原子操作 — 双格行为

BoardSkillSystem SHALL 提供以下双格原子操作：

| 方法 | 效果 | 前提条件 |
|---|---|---|
| `cell_swap(pos_a, pos_b)` | 交换两格物品（纯位置交换） | 非生成器，至少一边非空 |
| `cell_move(from, to)` | 物品移动，to 必须为空 | from 非空，to 为空 |
| `cell_merge(from, to)` | 尝试合成（委托 MergeSystem） | 两格物品可合成 |

#### Scenario: 交换两个有物品的格子

- **WHEN** pos A 有 drink Lv1，pos B 有 bread Lv2，调用 `cell_swap(A, B)`
- **THEN** A 变为 bread Lv2，B 变为 drink Lv1，返回 `[A, B]`

#### Scenario: 移动物品到空格

- **WHEN** pos A 有 drink Lv1，pos B 为空，调用 `cell_move(A, B)`
- **THEN** A 清空，B 变为 drink Lv1，B 弹跳动画，返回 `[A, B]`

#### Scenario: 合成两格物品

- **WHEN** A 和 B 各有 drink Lv2，调用 `cell_merge(A, B)`
- **THEN** A 清空，B 变为 drink Lv3，B 弹跳动画，返回 `[A, B]`

---

### Requirement: 棋盘查询辅助

BoardSkillSystem SHALL 提供查询辅助方法供技能 Callable 选格使用：

| 方法 | 返回 |
|---|---|
| `find_all_items()` | 所有有物品的非生成器格子 |
| `find_all_empty()` | 所有空格子（排除生成器） |
| `find_items_in_rect(a, b)` | 矩形区域内所有有物品的格子 |

#### Scenario: 查询所有物品和空格之和等于棋盘有效格数

- **WHEN** 棋盘为 7×9=63 格，含 1 个生成器，初始 7 个物品
- **THEN** `find_all_items().size() == 7`，`find_all_empty().size() == 55`，合计 62（排除生成器）

---

### Requirement: shake_board — 棋盘整体摇晃动画（可复用）

BoardSkillSystem SHALL 提供 `shake_board(duration, amplitude)` 方法。动画为 5 步衰减振荡（左右交替，振幅从 amplitude 递减到 0），最后一步归位。动画通过 Tween 驱动 `board.position.x`。

#### Scenario: 默认参数摇晃

- **WHEN** `shake_board()` 无参数调用
- **THEN** 棋盘以 amplitude=10 摇晃 0.25s，5 步衰减后归位

#### Scenario: 强震参数

- **WHEN** `shake_board(0.50, 22.0)` 被调用
- **THEN** 棋盘以 amplitude=22 摇晃 0.50s

---

### Requirement: animate_shuffle — 洗牌多格飞行动画

SHALL 实现三阶段动画：
1. **震** — `shake_board` 棋盘摇晃
2. **散** — 隐藏格子图标，创建浮动预览（top_level TextureRect），所有预览同时向外散射到随机偏移位置（0.2s，EASE_OUT，scale→0.85）
3. **聚** — 预览逐个错开（stagger 30ms）飞向目标位置（0.35s，EASE_IN_OUT，scale 弹跳恢复）

动画完成后清除预览，从数据层恢复格子图标，仅目标格播放弹跳动画。

#### Scenario: 7 个物品洗牌动画

- **WHEN** `animate_shuffle(anim_pairs)` 被调用，pairs 包含 7 条 from→to 映射
- **THEN** 棋盘先摇晃，然后 7 个物品图标散射→聚拢飞行，目标格弹跳

---

### Requirement: animate_clear_board — 清场爆散动画

SHALL 实现两阶段动画：
1. **大震** — `shake_board(0.50, 22.0)` 强震
2. **爆散** — 从原位烟花式爆散：burst 弹到 1.5x（0.15s），然后 `EASE_OUT` 先快后慢向外飘出屏幕（1.5s），同时缩小到 0 + 随机旋转 ±720°

爆散方向为 `normalize(item_position - board_center)`，即径向向外。动画完成后清除预览，格子保持清空。

#### Scenario: 清空 7 个物品

- **WHEN** `animate_clear_board(positions, items)` 被调用，数据层已清空
- **THEN** 棋盘大震后 7 个物品从原位径向爆散飞出屏幕

---

### Requirement: animate_throw — 投掷飞入动画

SHALL 实现物品从屏幕上方飞入的动画：
- 起始位置：目标列正上方，board 顶部 -300px 处
- `pivot_offset = cell_size / 4.0`（旋转锚点 = 左上角到中心的中点）
- 同时飞行（0.6s，EASE_OUT）+ 旋转 720°（方向随机）
- 落地后清理预览，格子弹跳

#### Scenario: 投掷物品到空格

- **WHEN** `animate_throw(target_pos, item)` 被调用
- **THEN** 物品预览从屏幕上方出现，边转边飞落到目标格，落地弹跳

---

### Requirement: 技能执行模式 — 数据先更新，动画纯视觉覆盖

所有技能的 execute Callable SHALL 遵循统一模式：
1. 收集受影响的格子/物品（通过查询辅助或 board 直接访问）
2. **数据层立即更新**（`board.set_item_at` 等）
3. 调用对应动画方法（纯视觉，使用浮动 TextureRect 覆盖）
4. 返回受影响的格子位置列表

动画完成后恢复格子图标（从已更新的数据读取），与数据层保持一致。

#### Scenario: 洗牌技能执行模式

- **WHEN** `_execute_shuffle` 被调用
- **THEN** 先 shuffle 数据→立即 set_item_at 更新→调用 animate_shuffle→返回 changed 位置

#### Scenario: 清场技能执行模式

- **WHEN** `_execute_clear` 被调用
- **THEN** 先收集物品→立即 set_item_at(null) 清空数据→调用 animate_clear_board→返回 changed 位置

---

### Requirement: 三个 V1 原型技能

系统 SHALL 包含以下三个已实现的技能：

| skill_id | 名称 | 冷却 | 效果 |
|---|---|---|---|
| `shuffle` | 猫咪 shuffle | 3s | 物品+空格位置随机重排，散→聚飞行 |
| `clear` | 猫咪爆破 | 8s | 大震后物品径向爆散飞出，棋盘清空 |
| `throw` | 猫咪投掷 | 2s | 随机 Lv1 物品从上方旋转飞入空格 |

#### Scenario: 洗牌改变棋盘布局

- **WHEN** `use_skill("shuffle")` 成功执行
- **THEN** 物品被重新分配到随机格子（含空格），位置上物品可能变化

#### Scenario: 清场后棋盘无物品

- **WHEN** `use_skill("clear")` 成功执行
- **THEN** 生成器格外的所有格子变为空

#### Scenario: 投掷生成新物品

- **WHEN** `use_skill("throw")` 成功执行且棋盘有空位
- **THEN** 随机空格出现一个随机 Lv1 物品，类型为 bread/dessert/drink 之一
