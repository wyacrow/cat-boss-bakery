# 项目状态报告 — 2026-07-05

## 一、已完成的工作

### 架构决策

| 决策 | 说明 |
|---|---|
| 移除 InventorySystem | 订单直接从棋盘扣物品，棋盘即缓冲区 |
| 移除 CollectSystem | 无三击收取，无独立库存 |
| 生成器在棋盘内 | Cell_4_3 为中心生成器格，非外部按钮 |
| 浪漫餐厅式生成 | 点击生成器格 → 消耗体力 → 随机Lv1 → 投最近空位 |
| 信号精简 | EventBus 从 11→7 信号，删除 collect_*/inventory_changed |

### 已实现系统

| 系统 | 文件 | 状态 |
|---|---|---|
| StaminaSystem | `scripts/systems/StaminaSystem.gd` | ✅ 完成 — 20上限，30s/点恢复，猫咪倍率可调 |
| GeneratorSystem | `scripts/systems/GeneratorSystem.gd` | ✅ 完成 — 体力消耗，33/33/33随机类型，最近空位查找 |
| GridBoard | `scripts/systems/GridBoard.gd` | ✅ 数据层完成 — 动态行列，合并/移动/交换，has_items/remove_items 订单查询，find_nearest_empty |
| MergeSystem | `scripts/systems/MergeSystem.gd` | ⚠️ 仅核心逻辑 — 2同LvN→LvN+1，缺自动合成扫描和选中状态机 |
| OrderSystem | `scripts/systems/OrderSystem.gd` | ✅ 完成 — 3槽，定时生成，Lv2+需求，棋盘直扣，猫咪金币倍率 |
| CatSystem | `scripts/systems/CatSystem.gd` | ✅ 完成 — 3猫全解锁，buff叠加 |
| EventBus | `scripts/core/EventBus.gd` | ✅ 完成 — 7信号 |
| GameStat | `scripts/core/EventBus.gd` | ✅ 完成 — 金币追踪，order_completed自动入账 |

### 已实现数据层

| 文件 | 状态 |
|---|---|
| `Item.gd` | ✅ — type/level/texture/display_name，can_merge_with，is_max_level |
| `OrderData.gd` | ✅ — id/requirements/base_reward/customer_cat |
| `ResourceDB.gd` | ✅ — 纹理路径映射 + 惰性加载缓存 |

### 已实现 UI 组件

| 组件 | 状态 |
|---|---|
| ItemCellButton | ✅ — 单击选中/拖动合并移动交换/生成器标记/拖放拦截 |
| OrderSlot | ✅ — 订单卡片显示，点击提交 |
| OrderBarManager | ✅ — 动态创建/管理 OrderSlot |
| 动画系统 | ✅ — PressShrinkAnimation, ReleaseExpandAnimation |

### 场景布局

| 区域 | 状态 |
|---|---|
| AreaA_Top (891px) | ✅ — TopHUDBar(右上0.7宽)+OrderBar(底部0.6高) |
| AreaB_Grid (1783px) | ✅ — GridBoard 四边10px padding，7×9=63格 |
| AreaC_Bottom (446px) | ✅ — BottomPanel 四边20px padding，separation=20 |
| 分辨率 | ✅ — 1440×3120，canvas_items stretch + expand aspect |

---

## 二、当前核心循环状态

```
✅ 体力恢复 ──→ ✅ 生成器点击 ──→ ✅ 物品生成到空位
                                      │
✅ 合并逻辑 ←── 拖拽合并/移动 ──────┘
     │
     ├── ⚠️ 缺自动合成扫描（选中状态机在 ItemCellButton，MergeSystem 未参与）
     │
✅ 订单生成 ──→ ✅ 订单提交 ──→ ✅ 棋盘扣物品 ──→ ✅ 金币入账
     │                                              │
     └── ⚠️ 缺 UI 刷新（stamina/gold 无显示绑定）──┘
```

---

## 三、距离可玩原型差什么

| # | 缺失项 | 优先级 | 预估 |
|---|---|---|---|
| 1 | **HUD 数据绑定** — StaminaBar/GoldDisplay 目前为纯 ColorRect，无 Label 显示数值 | P0 | 0.5 session |
| 2 | **BottomPanel 占位清理** — GeneratorButton（已废弃）、ItemInfoPanel、AutoMergeToggle 无功能 | P1 | 0.3 session |
| 3 | **ITEM_TYPES 三链恢复** — 当前 debug 期仅 drink 链，正式版需 bread/dessert/drink | P2 | 0.1 session |
| 4 | **CatSystem 连线** — 代码已完成，暂搁置 | P3 | 后续 |
| 5 | **初始测试物品清理** — debug 期保留 | P3 | - |

> **已纠正的误判**：
> - ~~MergeSystem 选中状态机~~ → 已通过 ItemCellButton 拖拽完成，MergeSystem.try_merge 逻辑完整
> - ~~GridBoard emit grid_changed~~ → 已在 merge/move/remove 四处 emit，功能完整

## 四、没有做 / 刻意不做

| 项目 | 原因 |
|---|---|
| InventorySystem | 订单直接从棋盘扣，不需要库存 |
| CollectSystem | 无三击收取，无独立库存 |
| 生成器外部按钮 | 生成器在棋盘内 Cell_4_3 |
| Auto-merge UI toggle | V1 原型暂不实现 |
| 订单过期机制 | 设计决策：V1 不过期 |
| 猫咪切换 UI | CatSystem V1 全解锁叠加，无需切换 |
| 音效 | 占位函数存在，无实际音频 |
| 存档 | V1 不持久化 |
| 素材 | 全部占位图（cat.png/food.png/cake.png） |

---

## 五、下一步建议顺序

```
1. HUD 数据绑定（stamina label + gold label → EventBus 信号）
2. BottomPanel 占位清理/替换
3. ITEM_TYPES 恢复三链（debug 结束后）
4. CatSystem + 其他后续
```
