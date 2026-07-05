## Why

猫咪系统 V1 设计（3 选 1 切换 buff）在原型验证阶段被评估为过度设计：治愈系合成游戏中，"切猫选 buff"需要玩家额外的决策操作，打断核心合成循环的流畅感。同时猫咪素材与顾客素材混用，导致 OrderSystem 的订单 NPC 头像无法独立管理。本次重构将猫咪系统简化为**隐式常驻被动 Buff**，并拆分为玩家猫和顾客猫两套素材体系，为后续订单系统和猫咪图鉴打好基础。

## What Changes

- **BREAKING**: CatSystem 从"选中激活单 Buff"改为"解锁即常驻、多 Buff 叠加"。移除 `select_cat()` / `active_cat` 等切换逻辑，改为 `get_xxx_multiplier()` 查询接口
- **BREAKING**: 移除猫咪选中 UI（原来可能存在的切换按钮区域），主界面不再显示猫咪激活状态
- **新增**: ResourceDB 中将 `CAT_TEXTURES` 拆分为 `CAT_SPRITES`（玩家猫咪素材，图鉴/装饰用）和 `CUSTOMER_CAT_TEXTURES`（顾客猫咪素材，订单 NPC 用）
- **新增**: 顾客猫池 — 5 只独立 NPC 猫，V1 随机分配至订单槽 CatIcon，不与订单类型绑定
- **简化**: V1 3 只玩家猫咪开局全解锁，解锁条件后续版本再设计
- **联动**: OrderSlot 的 CatIcon 节点改用顾客猫咪纹理

## Capabilities

### New Capabilities

- `cat-system-v2`: 隐式常驻被动 Buff 的猫咪系统，3 只猫全解锁叠加生效，提供 multiplier 查询接口
- `resource-db`: 集中式资源对应表，管理 Cat/Item/UI 三类纹理路径映射，惰性加载+缓存
- `customer-cat-pool`: 独立顾客猫咪池，5 只 NPC 猫，为订单系统提供随机顾客头像

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

- `scripts/systems/CatSystem.gd` — **重写**，移除选择逻辑，改为 passive buff 查询
- `scripts/data/ResourceDB.gd` — 拆分 CAT 表为 `CAT_SPRITES` + `CUSTOMER_CAT_TEXTURES`
- `scripts/ui/components/order_slot.gd` — CatIcon 改用 `CUSTOMER_CAT_TEXTURES` 随机纹理
- `scenes/ui/order_slot.tscn` — CatIcon 节点语义从"玩家猫"变为"顾客猫"
- `cat_bakery_merge_design.md` — 猫咪系统章节需同步更新
