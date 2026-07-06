class_name OrderData
extends RefCounted
# OrderData — 订单数据类
# 独立于 OrderSystem，供 EventBus、OrderSlot 等模块共用。
#
# 字段：
#   id             — 唯一标识，如 "order_001"
#   requirements   — 订单需求，格式 {"bread_3": 1, "dessert_2": 2}
#   base_reward    — 基础金币奖励（猫咪倍率在提交时由 OrderSystem 计算）
#   customer_cat   — 顾客猫类型（"tabby" | "black" | "white" 等）

var id: String = ""
var level_id: String = ""
var requirements: Dictionary = {}
var base_reward: int = 0
var customer_cat: String = ""


func _init(p_id: String = "", p_req: Dictionary = {}, p_reward: int = 0, p_cat: String = "", p_level_id: String = "") -> void:
	id = p_id
	level_id = p_level_id
	requirements = p_req
	base_reward = p_reward
	customer_cat = p_cat


func _to_string() -> String:
	return "OrderData(%s, level=%s, req=%s, reward=%d, cat=%s)" % [id, level_id, requirements, base_reward, customer_cat]
