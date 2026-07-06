class_name ResourceDB
extends RefCounted

# ============================================================
#  ResourceDB — 资源对应表（只读数据）
#
#  集中管理所有游戏实体的图片资源路径映射：
#    - Cat（玩家猫咪）     → 纹理（CAT_SPRITES）
#    - CustomerCat（顾客猫）→ 纹理（CUSTOMER_CAT_TEXTURES）
#    - Item（物品）        → 纹理（按 type_level 键）
#    - UI（界面）          → 纹理
#
#  用法：
#    var tex = ResourceDB.get_cat_sprite("bread_cat")
#    var tex = ResourceDB.get_customer_cat_texture("tabby")
#    var tex = ResourceDB.get_item_texture("dessert_3")
#    var ids = ResourceDB.get_all_customer_cat_ids()
# ============================================================

# ═══════════════════════════════════════════════════════════════
#  玩家猫咪 → 纹理路径映射
#  key: cat_id
#  用途：图鉴页、主界面装饰
# ═══════════════════════════════════════════════════════════════

const CAT_SPRITES := {
	# ── 面包猫（默认解锁，生产速度 +10%）──────────────────────
	"bread_cat": "res://sprites/cat.png",

	# ── 咖啡猫（默认解锁，金币收益 +20%）──────────────────────
	"coffee_cat": "res://sprites/cat.png",

	# ── 工程猫（默认解锁，体力恢复 +25%）──────────────────────
	"engineer_cat": "res://sprites/cat.png",
}

# ═══════════════════════════════════════════════════════════════
#  顾客猫咪 → 纹理路径映射
#  key: customer_id
#  用途：订单槽 CatIcon 显示，OrderSystem 随机分配
# ═══════════════════════════════════════════════════════════════

const CUSTOMER_CAT_TEXTURES := {
	"tabby": "res://sprites/art/单个订单猫1.png",     # 虎斑猫
	"black": "res://sprites/art/单个订单猫1.png",     # 黑猫
	"white": "res://sprites/art/单个订单猫1.png",     # 白猫
	"orange": "res://sprites/art/单个订单猫1.png",    # 橘猫
	"siamese": "res://sprites/art/单个订单猫1.png",   # 暹罗猫
}

# ═══════════════════════════════════════════════════════════════
#  Item → 纹理路径映射
#  key: "type_level"（与 Item 类的 type + level 一致）
#
#  三链 × 四级 = 12 种物品：
#    面包链: bread_1~4  (面粉→面团→面包→高级面包)
#    甜点链: dessert_1~4 (奶油→奶油霜→蛋糕→高级蛋糕)
#    饮品链: drink_1~4   (咖啡豆→咖啡粉→咖啡→高级咖啡)
# ═══════════════════════════════════════════════════════════════

const ITEM_TEXTURES := {
	# ── 面包链 ──────────────────────────────────────────────
	"bread_1": "res://sprites/bread/resized-bread1.png",     # 面粉
	"bread_2": "res://sprites/bread/resized-bread2.png",     # 面团
	"bread_3": "res://sprites/bread/resized-bread3.png",     # 面包
	"bread_4": "res://sprites/bread/resized-bread4.png",     # 高级面包

	# ── 甜点链 ──────────────────────────────────────────────
	"dessert_1": "res://sprites/cake.png",   # 奶油
	"dessert_2": "res://sprites/cake.png",   # 奶油霜
	"dessert_3": "res://sprites/cake.png",   # 蛋糕
	"dessert_4": "res://sprites/cake.png",   # 高级蛋糕

	# ── 饮品链 ──────────────────────────────────────────────
	"drink_1": "res://sprites/cof/resized-cof1.png",     # 咖啡豆
	"drink_2": "res://sprites/cof/resized-cof2.png",     # 咖啡粉
	"drink_3": "res://sprites/cof/resized-cof3.png",     # 咖啡
	"drink_4": "res://sprites/cof/resized-cof4.png",     # 高级咖啡
}

# ═══════════════════════════════════════════════════════════════
#  Item → 显示名称映射
# ═══════════════════════════════════════════════════════════════

const ITEM_NAMES := {
	"bread_1": "面粉",
	"bread_2": "面团",
	"bread_3": "面包",
	"bread_4": "高级面包",
	"dessert_1": "奶油",
	"dessert_2": "奶油霜",
	"dessert_3": "蛋糕",
	"dessert_4": "高级蛋糕",
	"drink_1": "咖啡豆",
	"drink_2": "咖啡粉",
	"drink_3": "咖啡",
	"drink_4": "高级咖啡",
}

# ═══════════════════════════════════════════════════════════════
#  UI → 纹理路径映射
# ═══════════════════════════════════════════════════════════════

const UI_TEXTURES := {
	"gold_icon": "res://sprites/art/金币.png",
	"reward_btn_bg": "res://sprites/rewardbtn.png",
}

# ═══════════════════════════════════════════════════════════════
#  纹理缓存（惰性加载，首次访问后缓存）
# ═══════════════════════════════════════════════════════════════

static var _texture_cache := {}


# ═══════════════════════════════════════════════════════════════
#  玩家猫咪查询
# ═══════════════════════════════════════════════════════════════

## 根据 cat_id 获取玩家猫咪纹理（图鉴/装饰用）
static func get_cat_sprite(cat_id: String) -> Texture2D:
	if CAT_SPRITES.has(cat_id):
		return _load_cached(CAT_SPRITES[cat_id])
	return null


## @deprecated: 使用 get_cat_sprite() 代替
static func get_cat_texture(cat_id: String) -> Texture2D:
	return get_cat_sprite(cat_id)


# ═══════════════════════════════════════════════════════════════
#  顾客猫咪查询
# ═══════════════════════════════════════════════════════════════

## 根据 customer_id 获取顾客猫纹理（订单 CatIcon 用）
static func get_customer_cat_texture(customer_id: String) -> Texture2D:
	if CUSTOMER_CAT_TEXTURES.has(customer_id):
		return _load_cached(CUSTOMER_CAT_TEXTURES[customer_id])
	return null


## 获取所有顾客猫 ID 列表（OrderSystem 随机分配用）
static func get_all_customer_cat_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in CUSTOMER_CAT_TEXTURES:
		ids.append(key)
	return ids


# ═══════════════════════════════════════════════════════════════
#  Item 查询
# ═══════════════════════════════════════════════════════════════

## 根据 "type_level" 键获取纹理（如 "bread_2", "dessert_3"）
static func get_item_texture(key: String) -> Texture2D:
	if ITEM_TEXTURES.has(key):
		return _load_cached(ITEM_TEXTURES[key])
	return null


## 根据 type + level 获取纹理
static func get_item_texture_by_parts(type: String, level: int) -> Texture2D:
	var key := "%s_%d" % [type, level]
	return get_item_texture(key)


## 为 Item 实例设置纹理
static func apply_texture_to(item: Item) -> void:
	if item == null:
		return
	var key := "%s_%d" % [item.type, item.level]
	item.texture = get_item_texture(key)


## 根据 "type_level" 键获取显示名称
static func get_item_name(key: String) -> String:
	if ITEM_NAMES.has(key):
		return ITEM_NAMES[key]
	return "未知物品"


## 根据 type + level 获取显示名称
static func get_item_name_by_parts(type: String, level: int) -> String:
	var key := "%s_%d" % [type, level]
	return get_item_name(key)


# ═══════════════════════════════════════════════════════════════
#  UI 查询
# ═══════════════════════════════════════════════════════════════

## 获取 UI 纹理（如 "gold_icon", "reward_btn_bg"）
static func get_ui_texture(ui_key: String) -> Texture2D:
	if UI_TEXTURES.has(ui_key):
		return _load_cached(UI_TEXTURES[ui_key])
	return null


# ═══════════════════════════════════════════════════════════════
#  内部：惰性加载 + 缓存
# ═══════════════════════════════════════════════════════════════

static func _load_cached(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex := load(path) as Texture2D
	if tex:
		_texture_cache[path] = tex
	return tex


## 清空纹理缓存（切换素材包时调用）
static func clear_cache() -> void:
	_texture_cache.clear()
