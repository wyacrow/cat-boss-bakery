class_name OrderSystem
extends Node

const LevelConfig := preload("res://scripts/data/LevelConfig.gd")

# OrderSystem — 订单系统（关卡配表制）
# 每个关卡预定义订单列表，2 个槽位展示，完成一个后从队列补入下一个。
# 关卡内全部订单完成后自动推进到下一关。
#
# 订单直接从棋盘扣除物品，不经过库存。
#
# 对外接口：
#   load_level(level_id: String)             加载关卡
#   submit_order(order_id: String) -> bool    提交订单
#   get_orders() -> Array[OrderData]         查询当前所有订单
#   cancel_order(order_id: String)            取消订单（调试用）
#   get_level_progress() -> Dictionary        {current: int, max: int}
#   advance_to_next_level()                   手动推进下一关

# ═══════════════════════════════════════════════════════════════
# 导出配置
# ═══════════════════════════════════════════════════════════════

@export var max_orders: int = 2
@export var cat_gold_multiplier: float = 1.0     # 咖啡猫激活时设为 1.2

## 棋盘引用（场景组装时注入，订单直接从棋盘扣物品）
var grid_board: Node = null

# ═══════════════════════════════════════════════════════════════
# 关卡状态
# ═══════════════════════════════════════════════════════════════

var _current_level_id: String = ""
var _order_queue: Array = []            # 当前关卡尚未展示的订单数据（Dictionary）
var _level_orders_completed: int = 0
var _level_total_orders: int = 0

# ═══════════════════════════════════════════════════════════════
# 内部状态
# ═══════════════════════════════════════════════════════════════

var _orders: Array = []   # 元素类型 OrderData，空槽为 null
var _order_counter: int = 0


# ═══════════════════════════════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	# 初始化槽位（全部为空），等待 GameScene 调用 load_level()
	_orders.resize(max_orders)
	for i in range(max_orders):
		_orders[i] = null

	# 监听槽位释放信号：OrderBarManager 消失动画完成后补入新订单
	if not EventBus.order_slot_freed.is_connected(_fill_slots):
		EventBus.order_slot_freed.connect(_fill_slots)

	print("OrderSystem: initialized, %d slots, waiting for level load" % max_orders)


# ═══════════════════════════════════════════════════════════════
# 关卡管理
# ═══════════════════════════════════════════════════════════════

## 加载指定关卡：清空现有槽位和队列，从配表读取订单列表，填满槽位
func load_level(level_id: String) -> void:
	var level_data: Dictionary = LevelConfig.get_level(level_id)
	if level_data.is_empty():
		print("OrderSystem: ERROR — level '%s' not found in LevelConfig" % level_id)
		return

	# 清空现有槽位（通知 UI 清理）
	for i in range(_orders.size()):
		if _orders[i] != null:
			_orders[i] = null

	# 清空队列
	_order_queue.clear()

	# 从配表加载订单数据入队
	var order_configs: Array = level_data.get("orders", [])
	for cfg in order_configs:
		_order_queue.append(cfg.duplicate())

	# 设置关卡状态
	_current_level_id = level_id
	_level_total_orders = order_configs.size()
	_level_orders_completed = 0

	# 同步 GameStat
	GameStat.orders_completed = 0
	GameStat.max_orders_target = _level_total_orders

	print("OrderSystem: level '%s' loaded — '%s', %d orders in queue" % [level_id, level_data.get("name", ""), _level_total_orders])

	# 通知 UI
	EventBus.level_loaded.emit(level_id, _level_total_orders)
	EventBus.order_progress_changed.emit(0, _level_total_orders)

	# 填满 2 个槽位
	_fill_slots()


## 推进到下一关
func advance_to_next_level() -> void:
	var next_id: String = LevelConfig.get_next_level_id(_current_level_id)
	if next_id != "":
		print("OrderSystem: advancing to '%s'" % next_id)
		load_level(next_id)
	else:
		print("OrderSystem: all levels cleared! Game complete.")
		# V1: 通关后不自动循环，可在此扩展通关界面


## 获取当前关卡进度
func get_level_progress() -> Dictionary:
	return {
		"current": _level_orders_completed,
		"max": _level_total_orders,
		"level_id": _current_level_id,
	}


# ═══════════════════════════════════════════════════════════════
# 槽位填充（队列 → 槽位）
# ═══════════════════════════════════════════════════════════════

## 遍历所有槽位，空槽从队列头部取订单填入
func _fill_slots() -> void:
	for i in range(max_orders):
		if _orders[i] == null and _order_queue.size() > 0:
			var order_cfg: Dictionary = _order_queue.pop_front()
			_order_counter += 1
			var order_id: String = "order_%03d" % _order_counter

			var order := OrderData.new(
				order_id,
				order_cfg.get("requirements", {}),
				order_cfg.get("base_reward", 0),
				order_cfg.get("customer_cat", ""),
				_current_level_id
			)

			_orders[i] = order
			EventBus.order_generated.emit(order)
			print("OrderSystem: order '%s' placed in slot %d (queue remaining: %d)" % [order_id, i, _order_queue.size()])


# ═══════════════════════════════════════════════════════════════
# 公开方法
# ═══════════════════════════════════════════════════════════════

## 注入棋盘引用（场景组装时调用）
func set_grid_board(node: Node) -> void:
	grid_board = node
	print("OrderSystem: grid_board set to ", node)


## 提交订单 → 校验棋盘 → 扣除物品 → 发放金币 → 清空槽位 → 补入队列 → 检查关卡完成
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

	# 更新关卡进度
	_level_orders_completed += 1
	EventBus.order_progress_changed.emit(_level_orders_completed, _level_total_orders)

	# 不立即 fill_slots — 等待 OrderBarManager 消失动画完成后通过 order_slot_freed 信号触发

	# 检查关卡是否完成
	if _level_orders_completed >= _level_total_orders:
		# 延迟一帧 emit，确保 UI（OrderBarManager 动画等）已处理完毕
		call_deferred("_emit_level_completed")

	return true


func _emit_level_completed() -> void:
	print("OrderSystem: level '%s' completed! %d/%d orders done" % [_current_level_id, _level_orders_completed, _level_total_orders])
	EventBus.level_completed.emit(_current_level_id)
	advance_to_next_level()


## 获取当前所有订单（含空槽返回 null）
func get_orders() -> Array:
	return _orders.duplicate()


## 取消订单（调试/测试用）
func cancel_order(order_id: String) -> void:
	var idx: int = _find_order_index(order_id)
	if idx != -1:
		_orders[idx] = null
		print("OrderSystem: order '%s' cancelled" % order_id)
		# 取消后尝试从队列补入
		_fill_slots()


## 设置猫咪金币倍率
func set_cat_gold_multiplier(mult: float) -> void:
	cat_gold_multiplier = mult
	print("OrderSystem: cat_gold_multiplier = %.1f" % mult)


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
