class_name CatSystem
extends Node

const ResourceDB := preload("res://scripts/data/ResourceDB.gd")

# ============================================================
#  CatSystem — 猫咪被动 Buff 系统
#
#  3 只猫咪隐式常驻，解锁即生效，buff 叠加。
#  V1 开局全解锁，无需玩家选择或操作。
#
#  Buff 表：
#    bread_cat    → 生产速度 +10%
#    coffee_cat   → 金币收益 +20%
#    engineer_cat → 体力恢复 +25%
#
#  用法：
#    var mult = cat_system.get_production_multiplier()   # → 1.10
#    var mult = cat_system.get_gold_multiplier()         # → 1.20
#    var mult = cat_system.get_stamina_regen_multiplier() # → 1.25
#    var ok   = cat_system.is_unlocked("bread_cat")      # → true
# ============================================================

# ── Buff 常量 ──────────────────────────────────────────────

const BUFF_PRODUCTION: float = 0.10
const BUFF_GOLD: float = 0.20
const BUFF_STAMINA_REGEN: float = 0.25

# ── 内部状态 ──────────────────────────────────────────────

var _unlocked: Dictionary = {}   # {cat_id: bool}


# ============================================================
#  生命周期
# ============================================================

func _ready() -> void:
	_ensure_initialized()
	print("CatSystem: initialized — %d cats unlocked" % _count_unlocked())


func _ensure_initialized() -> void:
	if not _unlocked.is_empty():
		return
	# V1: 开局全解锁
	for cat_id in ResourceDB.CAT_SPRITES:
		_unlocked[cat_id] = true


func _init_unlocks() -> void:
	_ensure_initialized()


# ============================================================
#  公开查询方法
# ============================================================

## 生产速度倍率 = 1.0 + (面包猫解锁 ? 0.10 : 0)
func get_production_multiplier() -> float:
	_ensure_initialized()
	var base := 1.0
	if _unlocked.get("bread_cat", false):
		base += BUFF_PRODUCTION
	return base


## 金币收益倍率 = 1.0 + (咖啡猫解锁 ? 0.20 : 0)
func get_gold_multiplier() -> float:
	_ensure_initialized()
	var base := 1.0
	if _unlocked.get("coffee_cat", false):
		base += BUFF_GOLD
	return base


## 体力恢复倍率 = 1.0 + (工程猫解锁 ? 0.25 : 0)
func get_stamina_regen_multiplier() -> float:
	_ensure_initialized()
	var base := 1.0
	if _unlocked.get("engineer_cat", false):
		base += BUFF_STAMINA_REGEN
	return base


## 查询指定猫咪是否已解锁
func is_unlocked(cat_id: String) -> bool:
	return _unlocked.get(cat_id, false)


## 获取所有猫咪解锁状态（图鉴 UI 用）
func get_all_unlock_status() -> Dictionary:
	return _unlocked.duplicate()


# ============================================================
#  V2 扩展接口（预留，V1 不调用）
# ============================================================

## 解锁指定猫咪（V2 加入解锁条件后使用）
func unlock_cat(cat_id: String) -> void:
	if not ResourceDB.CAT_SPRITES.has(cat_id):
		print("CatSystem: unknown cat_id '%s'" % cat_id)
		return
	if _unlocked.get(cat_id, false):
		return
	_unlocked[cat_id] = true
	print("CatSystem: cat '%s' unlocked!" % cat_id)


# ============================================================
#  内部
# ============================================================

func _count_unlocked() -> int:
	var count := 0
	for v in _unlocked.values():
		if v:
			count += 1
	return count
