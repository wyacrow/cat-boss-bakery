class_name LevelConfig
extends RefCounted

# ============================================================
#  LevelConfig — 关卡配表（只读数据）
#
#  定义每个关卡的订单列表、名称等信息。
#  OrderSystem 通过此表加载关卡订单队列。
#
#  用法：
#    var level = LevelConfig.get_level("level_01")
#    var count = LevelConfig.get_order_count("level_01")
#    var next = LevelConfig.get_next_level_id("level_01")
# ============================================================

const LEVELS := {
	"level_01": {
		"name": "初来乍到",
		"orders": [
			{
				"requirements": {"drink_2": 1},
				"base_reward": 20,
				"customer_cat": "tabby",
			},
			{
				"requirements": {"bread_2": 1},
				"base_reward": 20,
				"customer_cat": "black",
			},
			{
				"requirements": {"drink_3": 1},
				"base_reward": 30,
				"customer_cat": "white",
			},
		],
	},
	"level_02": {
		"name": "渐入佳境",
		"orders": [
			{
				"requirements": {"drink_3": 1},
				"base_reward": 30,
				"customer_cat": "tabby",
			},
			{
				"requirements": {"bread_3": 1},
				"base_reward": 30,
				"customer_cat": "orange",
			},
			{
				"requirements": {"drink_2": 1, "bread_2": 1},
				"base_reward": 40,
				"customer_cat": "siamese",
			},
		],
	},
}


# ═══════════════════════════════════════════════════════════════
#  公开静态方法
# ═══════════════════════════════════════════════════════════════

## 获取所有关卡 ID 列表（按顺序）
static func get_level_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in LEVELS:
		ids.append(key)
	return ids


## 获取指定关卡数据（含 name + orders），不存在返回空字典
static func get_level(level_id: String) -> Dictionary:
	if LEVELS.has(level_id):
		return LEVELS[level_id].duplicate(true)
	return {}


## 获取指定关卡的订单数量
static func get_order_count(level_id: String) -> int:
	if LEVELS.has(level_id):
		return LEVELS[level_id]["orders"].size()
	return 0


## 获取第一个关卡 ID
static func get_first_level_id() -> String:
	var ids := get_level_ids()
	if ids.size() > 0:
		return ids[0]
	return ""


## 获取下一个关卡 ID，没有则返回空字符串
static func get_next_level_id(current: String) -> String:
	var ids := get_level_ids()
	var idx := ids.find(current)
	if idx != -1 and idx + 1 < ids.size():
		return ids[idx + 1]
	return ""
