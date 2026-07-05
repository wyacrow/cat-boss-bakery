## 1. ResourceDB — 素材表拆分

- [x] 1.1 将 `CAT_TEXTURES` 重命名为 `CAT_SPRITES`（玩家猫咪素材），保留 bread_cat/coffee_cat/engineer_cat 三个条目
- [x] 1.2 新增 `CUSTOMER_CAT_TEXTURES` 字典，5 条记录（tabby/black/white/orange/siamese），V1 均指向 `res://sprites/cat.png`
- [x] 1.3 新增 `get_cat_sprite(cat_id)`、`get_customer_cat_texture(customer_id)`、`get_all_customer_cat_ids()` 查询方法
- [x] 1.4 保留 `get_cat_texture()` 为 deprecated 别名（向后兼容，内部委托给 `get_cat_sprite()`）

## 2. CatSystem — 重写为被动 Buff

- [x] 2.1 创建 `scripts/systems/CatSystem.gd`：无选择/激活逻辑，纯 multiplier 查询
- [x] 2.2 实现内部 `_unlocked: Dictionary` 状态，V1 初始化全为 true（惰性初始化，不依赖 scene tree）
- [x] 2.3 实现 `get_production_multiplier()`、`get_gold_multiplier()`、`get_stamina_regen_multiplier()` 查询方法
- [x] 2.4 实现 `is_unlocked(cat_id: String) -> bool` 查询方法
- [x] 2.5 惰性初始化 + `_ready()` 双重保障，无需注册到 GameScene 即可工作

## 3. OrderSystem — 接入顾客猫池

- [x] 3.1 移除硬编码 `const CAT_TYPES := ["tabby", "black", "white"]`
- [x] 3.2 `_pick_customer_cat()` 改为调用 `ResourceDB.get_all_customer_cat_ids()` 动态获取池
- [x] 3.3 订单生成时 `customer_cat` 字段从 5 只猫中随机选取

## 4. OrderSlot — 接入顾客猫纹理

- [x] 4.1 `_update_cat(cat_type)` 改为调用 `ResourceDB.get_customer_cat_texture(cat_type)` 加载纹理
- [x] 4.2 空槽或空 cat_type 时隐藏 CatIcon
- [x] 4.3 `set_order()` 已通过 `OrderData.customer_cat` 传递猫咪类型

## 5. 验证

- [x] 5.1 确认 Godot 编辑器能正常加载 GameScene（无 ext_resource 丢失错误）
- [x] 5.2 确认三个 OrderSlot 的 CatIcon 节点正常显示顾客猫纹理
- [x] 5.3 运行 `ResourceDB.clear_cache()` 验证缓存清理不报错
