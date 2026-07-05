## Context

猫咪系统 V1 采用"三选一激活"模式，玩家需手动切换猫咪以获取不同 buff。在原型验证阶段发现：治愈系合成游戏的核心循环（生成→合并→收集→订单）中，"切猫选 buff"打断了合成流畅感。同时猫咪素材（cat.png）被订单系统和猫咪本体混用，素材管理混乱。

本次设计将猫咪系统重构为**隐式常驻被动 Buff**，并拆分为三个独立关注点：CatSystem（buff 逻辑）、ResourceDB（素材映射）、CustomerCatPool（订单 NPC 头像）。

## Goals / Non-Goals

**Goals:**
- CatSystem 提供只读的 multiplier 查询，所有已解锁猫的 buff 叠加生效
- ResourceDB 集中管理三种实体（Cat/Item/UI）的纹理映射，惰性加载
- 顾客猫素材独立于玩家猫素材，为 OrderSystem 提供可扩展的 NPC 头像池
- V1 简化：3 只猫开局全解锁，顾客猫池 5 只全可用

**Non-Goals:**
- 猫咪升级/养成系统（V2+）
- 猫咪解锁条件设计（V2+）
- 顾客猫与订单类型的绑定逻辑（V2+）
- 猫咪动画、装饰系统（V2+）

## Decisions

### D1: CatSystem 改为纯 multiplier 查询器

**决策**: CatSystem 不再维护"当前激活哪只猫"的状态，改为提供三个静态 multiplier 查询方法。每只猫的解锁状态存为 `Dictionary[String, bool]`，buff 叠加公式为 `1.0 + Σ(unlocked ? buff_value : 0)`。

**替代方案**: 用 Signal + EventBus 广播 buff 变更。否决原因：buff 值只在查询时被消费（Generator 生成前、Order 结算时），没有实时监听需求，用直接方法调用更简洁、有返回值。

**buff 映射表**:

| cat_id | effect_type | value | multiplier |
|--------|-------------|-------|------------|
| `bread_cat` | production_speed | +10% | 1.10 |
| `coffee_cat` | gold_reward | +20% | 1.20 |
| `engineer_cat` | stamina_regen | +25% | 1.25 |

### D2: ResourceDB 拆分为三个 namespace

**决策**: ResourceDB 提供三个独立的 const 映射表 + static 查询方法：

- `CAT_SPRITES` → `get_cat_sprite(cat_id)`
- `ITEM_TEXTURES` → `get_item_texture(key)`
- `CUSTOMER_CAT_TEXTURES` → `get_customer_cat_texture(customer_id)`

纹理通过 `load()` 惰性加载到 `_texture_cache`，首次访问后缓存。`clear_cache()` 支持热切换素材包。

**替代方案**: 用 Godot Resource 文件 (.tres) 存储映射。否决原因：V1 原型阶段用纯代码表更灵活、易修改、无编辑器依赖。

### D3: CustomerCatPool 为轻量数据源

**决策**: 在 ResourceDB 中定义 `CUSTOMER_CAT_TEXTURES` 字典（不创建独立类），key 为 `customer_cat_01` ~ `customer_cat_05`。OrderSystem 生成订单时，从池中随机选取一个 customer_id 连同订单数据一起下发。OrderSlot 收到后通过 `ResourceDB.get_customer_cat_texture(id)` 设置 CatIcon。

**替代方案**: 创建 `CustomerCat` 类（RefCounted）。否决原因：V1 顾客猫只有头像纹理一个属性，不需要封装为类。后续加入名字/性格等属性时再抽取。

### D4: V1 开局全解锁

**决策**: `CatSystem._unlocked` 在 `_ready()` 中初始化为 `{bread_cat: true, coffee_cat: true, engineer_cat: true}`。无需解锁流程、无需持久化。

**替代方案**: 通过配置文件控制初始解锁状态。V2 再做。

## Risks / Trade-offs

- **叠加后的数值平衡**: 3 只猫全解锁后 buff 叠加（1.1×1.2×1.25=1.65），V1 不做数值平衡调整，后续 playtest 反馈再迭代 → 在 `cat_bakery_merge_design.md` 中标注 buff 值为 V1 初始值，可调
- **CatAPI 签名变更**: `select_cat()` / `active_cat` 被移除，现有调用方（如果有）会编译失败 → V1 原型阶段尚无调用方，零影响
- **顾客猫 5 只全用 cat.png**: 视觉上没有区分度 → 纯占位，等美术素材到位后只改 `CUSTOMER_CAT_TEXTURES` 路径即可
