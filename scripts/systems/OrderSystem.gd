class_name OrderSystem
extends Node

const ResourceDB := preload("res://scripts/data/ResourceDB.gd")

# OrderSystem — 订单系统
# 管理 3 个订单槽位，每 60 秒自动生成新订单（V1 不过期）。
# 订单直接从棋盘扣除物品，不经过库存。
#
# 订单生成规则（来自 spec）：
#   - 需求 1~2 种物品，每种 1~3 个
#   - 物品等级仅 Lv2~Lv4（权重：Lv2=50%, Lv3=35%, Lv4=15%）
#   - 三种链等概率选择（面包 33% / 甜点 33% / 饮品 33%）
#   - 2 种物品时不可重复同链
#   - 基础奖励 = Σ(item.level × 10 × quantity)
#   - 最终奖励 = 基础奖励 × cat_gold_multiplier
#
# 对外接口：
#   submit_order(order_id: String) -> bool  提交订单
#   get_orders() -> Array[OrderData]       查询当前所有订单
#   cancel_order(order_id: String)          取消订单（调试用）

# ═══════════════════════════════════════════════════════════════
# 导出配置
# ═══════════════════════════════════════════════════════════════

@export var max_orders: int = 2
@export var generation_interval: float = 60.0   # 秒
@export var cat_gold_multiplier: float = 1.0     # 咖啡猫激活时设为 1.2

## 棋盘引用（场景组装时注入，订单直接从棋盘扣物品）
var grid_board: Node = null

# ═══════════════════════════════════════════════════════════════
# 内部状态
# ═══════════════════════════════════════════════════════════════

var _orders: Array = []   # 元素类型 OrderData，空槽为 null
var _order_counter: int = 0
var _gen_timer: Timer

# 物品池常量
const ITEM_TYPES := ["drink"]  # 咖啡专链（临时，V1 原型验证用）
const LEVEL_WEIGHTS := [2, 2, 2, 2, 2, 2, 2, 2, 2, 2,   # Lv2: 50% (10/20)
						3, 3, 3, 3, 3, 3, 3,               # Lv3: 35% (7/20)
						4, 4, 4]                            # Lv4: 15% (3/20)


# ═══════════════════════════════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	# 初始化槽位（全部为空）
	_orders.resize(max_orders)
	for i in range(max_orders):
		_orders[i] = null

	# 启动定时器
	_gen_timer = Timer.new()
	_gen_timer.one_shot = false
	_gen_timer.timeout.connect(_on_generation_tick)
	add_child(_gen_timer)
	# 延迟一帧生成初始订单（timer 在初始订单完成后启动），确保 GameScene 已完成连线
	call_deferred("_generate_initial_orders")

	print("OrderSystem: initialized, %d slots, interval=%.1fs" % [max_orders, generation_interval])


# ═══════════════════════════════════════════════════════════════
# 公开方法
# ═══════════════════════════════════════════════════════════════

## 注入棋盘引用（场景组装时调用）
func set_grid_board(node: Node) -> void:
	grid_board = node
	print("OrderSystem: grid_board set to ", node)


## 提交订单 → 校验棋盘 → 扣除物品 → 发放金币 → 清空槽位
func submit_order(order_id: String) -> bool:
	var idx: int = _find_order_index(order_id)
	if idx == -1:
		print("OrderSystem: submit failed — order '%s' not found" % order_id)
		return false

	var order = _orders[idx]
	if order == null:
		return false

	# 校验棋盘
	if not _validate_grid(order.requirements):
		print("OrderSystem: submit failed — grid insufficient for '%s'" % order_id)
		return false

	# 从棋盘扣除物品
	if not _consume_grid(order.requirements):
		return false

	# 计算最终奖励
	var final_reward: int = int(order.base_reward * cat_gold_multiplier)
	EventBus.order_completed.emit(order_id, final_reward)

	print("OrderSystem: order '%s' completed, reward=%d (base=%d, mult=%.1f)" % [order_id, final_reward, order.base_reward, cat_gold_multiplier])

	# 清空槽位
	_orders[idx] = null

	return true


## 获取当前所有订单（含空槽返回 null）
func get_orders() -> Array:
	return _orders.duplicate()


## 取消订单（调试/测试用）
func cancel_order(order_id: String) -> void:
	var idx: int = _find_order_index(order_id)
	if idx != -1:
		_orders[idx] = null
		print("OrderSystem: order '%s' cancelled" % order_id)


## 设置猫咪金币倍率
func set_cat_gold_multiplier(mult: float) -> void:
	cat_gold_multiplier = mult
	print("OrderSystem: cat_gold_multiplier = %.1f" % mult)


## 获取当前空余槽位数
func get_empty_slot_count() -> int:
	var count: int = 0
	for o in _orders:
		if o == null:
			count += 1
	return count


# ═══════════════════════════════════════════════════════════════
# 订单生成
# ═══════════════════════════════════════════════════════════════

func _generate_initial_orders() -> void:
	for i in range(max_orders):
		var order: OrderData = _generate_order()
		_orders[i] = order
		EventBus.order_generated.emit(order)
	print("OrderSystem: %d initial orders generated" % max_orders)
	# 初始订单填充完毕后启动定时生成
	_gen_timer.start(generation_interval)


func _on_generation_tick() -> void:
	if get_empty_slot_count() == 0:
		return  # 所有槽位已满，跳过

	var order: OrderData = _generate_order()
	var idx: int = _find_first_empty_slot()
	if idx != -1:
		_orders[idx] = order
		EventBus.order_generated.emit(order)
		print("OrderSystem: new order '%s' generated in slot %d" % [order.id, idx])


func _generate_order():   # -> OrderData
	_order_counter += 1
	var order_id: String = "order_%03d" % _order_counter

	# 需求种类数：1 或 2（等概率）。订单最多 2 种物品，不可超过。
	const MAX_ITEM_TYPES_PER_ORDER := 2
	var type_count: int = 1 if randi() % 2 == 0 else 2
	type_count = min(type_count, ITEM_TYPES.size())
	type_count = min(type_count, MAX_ITEM_TYPES_PER_ORDER)

	var requirements: Dictionary = {}
	var used_types: Array[String] = []

	for _i in range(type_count):
		var item_type: String = _pick_item_type(used_types)
		used_types.append(item_type)
		var level: int = _pick_level()
		var quantity: int = randi_range(1, 3)
		var key: String = "%s_%d" % [item_type, level]
		requirements[key] = quantity

	# 计算基础奖励
	var base_reward: int = _calc_base_reward(requirements)

	# 随机顾客猫
	var cat: String = _pick_customer_cat()

	return OrderData.new(order_id, requirements, base_reward, cat)


func _pick_item_type(exclude: Array[String]) -> String:
	var pool: Array = ITEM_TYPES.duplicate()
	for t in exclude:
		pool.erase(t)
	if pool.is_empty():
		return ITEM_TYPES[0]  # 兜底：无可选类型时返回第一种
	return pool[randi() % pool.size()]


func _pick_level() -> int:
	return LEVEL_WEIGHTS[randi() % LEVEL_WEIGHTS.size()]


func _pick_customer_cat() -> String:
	var pool: Array[String] = ResourceDB.get_all_customer_cat_ids()
	return pool[randi() % pool.size()]


func _calc_base_reward(requirements: Dictionary) -> int:
	var total: int = 0
	for key: String in requirements:
		var parts: PackedStringArray = key.split("_")
		var level: int = int(parts[1])
		var quantity: int = requirements[key]
		total += level * 10 * quantity
	return total


# ═══════════════════════════════════════════════════════════════
# 棋盘交互（通过注入的 grid_board）
# ═══════════════════════════════════════════════════════════════

func _validate_grid(requirements: Dictionary) -> bool:
	if grid_board == null:
		print("OrderSystem: WARNING — grid_board not set, cannot validate!")
		return false
	return grid_board.has_items(requirements)


func _consume_grid(requirements: Dictionary) -> bool:
	if grid_board == null:
		print("OrderSystem: WARNING — grid_board not set, cannot consume!")
		return false
	return grid_board.remove_items(requirements)


# ═══════════════════════════════════════════════════════════════
# 工具方法
# ═══════════════════════════════════════════════════════════════

func _find_order_index(order_id: String) -> int:
	for i in range(_orders.size()):
		var o: OrderData = _orders[i]
		if o != null and o.id == order_id:
			return i
	return -1


func _find_first_empty_slot() -> int:
	for i in range(_orders.size()):
		if _orders[i] == null:
			return i
	return -1
