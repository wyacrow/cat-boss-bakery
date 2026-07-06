## Context

当前项目处于 V1 原型验证期（调试期），仅饮品链（drink）激活。面包素材已就绪但未接入。系统架构上，`GeneratorSystem` 和 `OrderSystem` 均硬编码了 `ITEM_TYPES = ["drink"]`，且 `ResourceDB` 中面包纹理仍指向占位图 `food.png`。

棋盘为 7×9=63 格，现有 1 个生成器位于 Cell_8_3（右下角），图标为咖啡机。

## Goals / Non-Goals

**Goals:**
- 激活面包合成链（bread Lv1~4），与饮品链并行
- 新增面包专用生成器（烘焙机），与现有饮品生成器（咖啡机）共存
- 订单池从单链扩展为双链（drink + bread）
- 面包纹理从占位图替换为实际素材

**Non-Goals:**
- 不激活甜点链（dessert）——素材未就绪，继续使用占位 cake.png
- 不改变生成器在棋盘中的位置逻辑（仍为固定 cell）
- 不引入三个以上的生成器
- 不改变合并/订单核心规则

## Decisions

### 1. GeneratorSystem 增加 `generator_type` 属性

**决策**: 在 `GeneratorSystem` 类上新增 `generator_type: String` 属性（默认 `"drink"`），调用 `try_generate()` 时仅产出该类型的物品。

**替代方案**: 为每种类型创建子类 → 拒绝，过度设计。一个简单属性即可满足需求。

**理由**: 现有 `ITEM_TYPES` 常量数组被替换为按 `generator_type` 生成。每个棋盘上的生成器 cell 对应一个 `GeneratorSystem` 实例，实例化时指定类型。

### 2. 两个独立 GeneratorSystem 实例

**决策**: `GridBoard` 持有两个 `GeneratorSystem` 实例：一个 `generator_type = "drink"`，一个 `generator_type = "bread"`。通过生成器 cell 的 `generator_type` 属性路由到正确的实例。

**替代方案**: 单个 GeneratorSystem 维护类型映射表 → 增加复杂度，两个独立实例更清晰，符合"一系统一职责"原则。

### 3. ItemCellButton 新增 `generator_type` export 变量

**决策**: `ItemCellButton` 新增 `@export var generator_type: String = ""`。当 `is_generator = true` 时，根据 `generator_type` 选择图标（`"drink"` → 咖啡机，`"bread"` → 烘焙机）。

**理由**: 图标选择逻辑在 cell 内部，无需 GridBoard 干预。场景文件直接配置每个生成器格位的类型。

### 4. 面包生成器位置

**决策**: 在 Cell_6_3（row 6, col 3）设置为面包生成器（`is_generator = true, generator_type = "bread"`），位于现有饮品生成器 Cell_8_3 上方两行。

**理由**: 两个生成器在同一列，视觉对称；面包生成器在中间位置，饮品生成器在底部，便于玩家区分和操作。

### 5. OrderSystem ITEM_TYPES 扩展

**决策**: `ITEM_TYPES` 从 `["drink"]` 改为 `["drink", "bread"]`。订单随机选择物品类型时等概率从两条链中选择。

**理由**: 简单的数组扩展，对现有订单生成逻辑透明。

### 6. ResourceDB 面包纹理映射

**决策**: 将 `ITEM_TEXTURES["bread_1".."bread_4"]` 从 `res://sprites/food.png` 替换为：
- `bread_1` → `resized-bread1.png`（面粉）
- `bread_2` → `resized-bread2.png`（面团）
- `bread_3` → `resized-bread3.png`（面包）
- `bread_4` → `resized-bread4.png`（高级面包，用 bread4-6 中选代表）

**理由**: 6 张 bread 素材可能有多余（如不同变体），Lv1~4 各选一张代表，剩余备用。

### 7. 初始物品布局扩展

**决策**: 在 GridBoard._place_initial_items() 中新增面包链初始物品，放在棋盘中间区域（row 2~3），与顶部饮品链区分。

## Risks / Trade-offs

- [面包素材 rank 对应关系] → 当前有 6 张 bread 素材，需确认哪 4 张对应 Lv1~4。先按 bread1→Lv1, bread2→Lv2, bread3→Lv3, bread4→Lv4 映射，bread5/6 预留后续使用。
- [生成器间距] → 两个生成器同列可能让玩家混淆。如果测试中发现体验不佳，后续调整位置即可，不影响数据结构。
- [订单难度] → 双链后订单物品匹配概率降低，玩家需同时维护两条合成链。V1 原型期先观察数据，不调整订单难度参数。
