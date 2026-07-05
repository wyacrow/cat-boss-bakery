class_name OrderBarManager
extends Node

const ResourceDB := preload("res://scripts/data/ResourceDB.gd")

# OrderBarManager — 订单栏视觉管理器
# 管理 OrderSlot 实例的创建/销毁/定位/位移动画。
# 监听 EventBus 信号，与 OrderSystem 通过事件解耦。
#
# 定位规则：
#   - 3 个锚定位置，订单从左到右依次填充
#   - 左侧订单提交后，右侧订单带动画左移
#   - 新订单始终出现在最右侧可用位置

# ═══════════════════════════════════════════════════════════════
# 导出配置
# ═══════════════════════════════════════════════════════════════

## 2 个槽位的锚定位置（相对于 OrderBar 的 offset）
@export var slot_positions: Array[Vector2] = [
	Vector2(20, 236),
	Vector2(590, 236),
]
## 动画参数
@export var appear_duration: float = 0.2
@export var disappear_duration: float = 0.25
@export var shift_duration: float = 0.3
@export var stagger_delay: float = 0.08   # 批量生成时的错开间隔

# ═══════════════════════════════════════════════════════════════
# 内部状态
# ═══════════════════════════════════════════════════════════════

const _slot_scene := preload("res://scenes/ui/order_slot.tscn")

var _order_system: Node = null
var _active_slots: Array = []        # Array[OrderSlot]，按位置 0..N-1 排序
var _pending_orders: Array = []      # 待处理的订单队列（错开动画用）
var _is_processing: bool = false


# ═══════════════════════════════════════════════════════════════
# 公开方法
# ═══════════════════════════════════════════════════════════════

func setup(p_order_system: Node) -> void:
	_order_system = p_order_system

	# 监听 EventBus
	if not EventBus.order_generated.is_connected(_on_order_generated):
		EventBus.order_generated.connect(_on_order_generated)
	if not EventBus.order_completed.is_connected(_on_order_completed):
		EventBus.order_completed.connect(_on_order_completed)

	print("OrderBarManager: setup complete, listening to EventBus")


# ═══════════════════════════════════════════════════════════════
# EventBus 回调
# ═══════════════════════════════════════════════════════════════

func _on_order_generated(order) -> void:
	# 加入待处理队列，错开动画
	# 使用 call_deferred 确保同步多次 emit 时先全部入队再逐个处理
	_pending_orders.append(order)
	if not _is_processing:
		call_deferred("_process_pending")


func _on_order_completed(order_id: String, _reward_gold: int) -> void:
	var idx: int = _find_slot_index(order_id)
	if idx == -1:
		return

	var slot = _active_slots[idx]
	_active_slots.remove_at(idx)

	# 播放消失动画，完成后销毁
	slot.animate_disappear()
	slot.disappear_finished.connect(_on_slot_removed.bind(slot), CONNECT_ONE_SHOT)

	# 剩余槽位左移
	_shift_all_slots()


# ═══════════════════════════════════════════════════════════════
# 槽位管理
# ═══════════════════════════════════════════════════════════════

func _process_pending() -> void:
	_is_processing = true

	while _pending_orders.size() > 0:
		if _active_slots.size() >= slot_positions.size():
			_pending_orders.clear()
			break

		var order = _pending_orders.pop_front()
		_create_slot(order)

		if _pending_orders.size() > 0:
			await get_tree().create_timer(stagger_delay).timeout

	_is_processing = false


func _create_slot(order) -> void:
	var slot := _slot_scene.instantiate()
	slot.set_order_system(_order_system)

	var target_pos := slot_positions[_active_slots.size()]
	slot.position = target_pos

	add_child(slot)
	_active_slots.append(slot)

	slot.set_order(order)
	slot.set_gold_icon_texture(ResourceDB.get_ui_texture("gold_icon"))
	slot.animate_appear(appear_duration)

	print("OrderBarManager: slot '%s' created at position %d" % [order.id, _active_slots.size() - 1])


func _shift_all_slots() -> void:
	for i in range(_active_slots.size()):
		var target_pos := slot_positions[i]
		_active_slots[i].animate_to_position(target_pos, shift_duration)


func _find_slot_index(order_id: String) -> int:
	for i in range(_active_slots.size()):
		if _active_slots[i].order_id == order_id:
			return i
	return -1


func _on_slot_removed(slot: OrderSlot) -> void:
	if is_instance_valid(slot):
		slot.queue_free()
