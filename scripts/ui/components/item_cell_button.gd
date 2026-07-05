class_name ItemCellButton
extends Button

# ============================================================
#  ItemCellButton — 棋盘格子按钮
#
#  两种交互：
#    单击  — 选中（全局互斥）
#    拖动  — 合并 / 移动 / 交换
#
#  拖动落点行为：
#    空格子   → 移动物品 + 选中目标 + 弹起动画
#    同物品   → 合并升级
#    不同物品 → 交换
#    原位/取消 → 恢复 + 弹起动画
# ============================================================

const DRAG_PREVIEW_SCENE := preload("res://scenes/ui/drag_preview.tscn")

# ── 信号 ──────────────────────────────────────────────────

signal cell_pressed(position: Vector2i)
signal cell_released(position: Vector2i)
signal merge_request(from_pos: Vector2i, to_pos: Vector2i)
signal move_request(from_pos: Vector2i, to_pos: Vector2i)

# ── 公开数据 ──────────────────────────────────────────────

@export var is_generator: bool = false

var cell_position: Vector2i = Vector2i.ZERO
var item: Item = null
var is_selected: bool = false

static var current_selected: ItemCellButton = null  # 全局唯一选中

# ── 动画 ──────────────────────────────────────────────────

var press_animation: ButtonAnimation
var release_animation: ButtonAnimation

@export_group("Release Animation")
@export var release_scale_peak: float = 1.3
@export var release_scale_dip: float = 0.9
@export var release_duration: float = 0.3

# ── 私有状态 ──────────────────────────────────────────────

# 拖动状态
var _mouse_pressed: bool = false
var _is_dragging: bool = false
var _drag_result: String = ""  # "same" | "empty" | "different" | "cancelled"

# ── 子节点引用 ────────────────────────────────────────────

var _selection_frame: ColorRect
var _drag_overlay: ColorRect
var _item_icon: TextureRect
var _effects: EffectsSystem = null


# ============================================================
#  生命周期
# ============================================================

func _ready() -> void:
	_selection_frame = get_node_or_null("SelectionFrame")
	_drag_overlay   = get_node_or_null("DragOverlay")
	_item_icon       = get_node_or_null("ItemIcon")

	# 确保视觉覆盖层不拦截鼠标事件
	if _selection_frame:
		_selection_frame.mouse_filter = MOUSE_FILTER_IGNORE
	if _drag_overlay:
		_drag_overlay.mouse_filter = MOUSE_FILTER_IGNORE

	if is_generator:
		_setup_generator_visual()

	_setup_animations()
	_setup_signals()
	_init_visual_state()


func _setup_generator_visual() -> void:
	# 生成器格视觉：深色底 + 图标
	self_modulate = Color(0.3, 0.4, 0.6, 1.0)
	if _item_icon:
		_item_icon.texture = preload("res://sprites/food.png")
		_item_icon.visible = true


func _setup_animations() -> void:
	press_animation = PressShrinkAnimation.new()
	press_animation.target = self

	release_animation = ReleaseExpandAnimation.new()
	release_animation.target = self


	_apply_animation_params()


func _apply_animation_params() -> void:
	if release_animation:
		release_animation.scale_peak = release_scale_peak
		release_animation.scale_dip  = release_scale_dip
		release_animation.duration   = release_duration


func _setup_signals() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _init_visual_state() -> void:
	if _selection_frame:
		_selection_frame.visible = false
	if _drag_overlay:
		_drag_overlay.visible = false


func set_effects_system(effects: EffectsSystem) -> void:
	_effects = effects


# ============================================================
#  输入处理
# ============================================================

func _on_button_down() -> void:
	if is_generator:
		# 生成器格：不参与选中/拖动，只发信号
		if current_selected:
			current_selected.deselect()
	elif item != null:
		_claim_global_selection()
		if _selection_frame:
			_selection_frame.visible = true
			_selection_frame.move_to_front()
	else:
		if current_selected:
			current_selected.deselect()

	_mouse_pressed = true
	_is_dragging   = false
	_drag_result   = ""

	cell_pressed.emit(cell_position)


func _on_button_up() -> void:
	# 拖动结束后的残余 button_up → 忽略
	if _is_dragging or not _mouse_pressed:
		return

	_mouse_pressed = false

	if item:
		play_release_animation()


# ============================================================
#  拖放系统
# ============================================================

# -- 拖动启动 -------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _mouse_pressed or is_generator:
		return

	if event is InputEventMouseMotion and not _is_dragging and item != null:
		if not get_global_rect().has_point(get_global_mouse_position()):
			_start_dragging()


func _start_dragging() -> void:
	_is_dragging = true

	if _item_icon:
		_item_icon.visible = false

	force_drag(_make_drag_data(), make_drag_preview())


func _make_drag_data() -> Dictionary:
	return {
		"item":          item,
		"from_position": cell_position,
		"source_button": self,
	}


func make_drag_preview() -> Control:
	var preview: Control = DRAG_PREVIEW_SCENE.instantiate()
	var icon := preview.get_node("ItemIcon") as TextureRect

	if item and item.texture:
		icon.texture = item.texture

	return preview


# -- 落点处理 -------------------------------------------------

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if is_generator:
		return false
	if not (data is Dictionary and data.has("item")):
		return false

	var source_item: Item = data["item"]
	var from_pos: Vector2i = data["from_position"]

	# 拖回原位 → 不显示提示
	if from_pos == cell_position:
		if _effects:
			_effects.hide_any_hint()
		return true

	# 可合成 → 显示合并提示光环
	if item != null and item.can_merge_with(source_item) and not item.is_max_level() and _effects:
		_effects.show_merge_hint(cell_position, item)
	else:
		# 当前悬停格不可合成 → 隐藏提示
		if _effects:
			_effects.hide_any_hint()

	return true


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_pos: Vector2i     = data["from_position"]
	var source_item: Item       = data["item"]
	var source_button: ItemCellButton = data["source_button"]

	# 1. 记录落点类型
	if from_pos == cell_position:
		source_button._drag_result = "same"
	elif item == null:
		source_button._drag_result = "empty"
	else:
		source_button._drag_result = "different"

	# 2. 原位放下 → 不做数据交换
	if from_pos == cell_position:
		return

	# 3. 合并 / 移动 / 交换
	if item != null and source_item != null and item.can_merge_with(source_item):
		_do_merge(source_item, source_button, from_pos)
	elif item == null:
		_do_move_to_empty(source_item, source_button, from_pos)
	else:
		_do_swap(source_item, source_button, from_pos)


func _do_merge(_source_item: Item, _source_button: ItemCellButton, from_pos: Vector2i) -> void:
	# 数据操作交由 GridBoard 处理
	merge_request.emit(from_pos, cell_position)


func _do_move_to_empty(_source_item: Item, _source_button: ItemCellButton, from_pos: Vector2i) -> void:
	# 数据操作 + 选中 + 动画 交由 GridBoard 处理
	move_request.emit(from_pos, cell_position)


func _do_swap(_source_item: Item, _source_button: ItemCellButton, from_pos: Vector2i) -> void:
	# 数据操作交由 GridBoard 处理
	move_request.emit(from_pos, cell_position)


# -- 拖动结束 -------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _is_dragging:
		if _drag_result == "":
			_drag_result = "cancelled"
		# 拖拽结束 → 清除合并提示
		if _effects:
			_effects.hide_any_hint()
		_finish_drag()


func _finish_drag() -> void:
	if not _is_dragging:
		return

	if _drag_result == "same" or _drag_result == "cancelled":
		_restore_icon()

	match _drag_result:
		"same", "cancelled":
			play_release_animation()

	_is_dragging = false
	_mouse_pressed = false
	_drag_result   = ""
	# force_drag 后 Button 内部的 button_pressed 不会自动复位，
	# 导致下次点击先触发 button_up（释放）再触发 button_down，需要点两次。
	button_pressed = false


func _restore_icon() -> void:
	if _item_icon and item:
		_item_icon.visible = true


# ============================================================
#  选中状态（全局互斥）
# ============================================================

func _claim_global_selection() -> void:
	if current_selected and current_selected != self:
		current_selected.deselect()
	is_selected = true
	current_selected = self


func select() -> void:
	if not item:
		return
	_claim_global_selection()
	if _selection_frame:
		_selection_frame.visible = true
		_selection_frame.move_to_front()


func deselect() -> void:
	is_selected = false
	if _selection_frame:
		_selection_frame.visible = false
	if current_selected == self:
		current_selected = null


func toggle_selection() -> void:
	if is_selected:
		deselect()
	else:
		select()


# ============================================================
#  物品管理
# ============================================================

func set_item(new_item: Item) -> void:
	item = new_item
	_update_icon()


func clear_item() -> void:
	item = null
	_update_icon()


func _update_icon() -> void:
	if not _item_icon:
		return
	if item and item.texture:
		_item_icon.texture = item.texture
		_item_icon.visible = true
	else:
		_item_icon.visible = false


# ============================================================
#  视觉
# ============================================================

func show_drag_overlay() -> void:
	if _drag_overlay:
		_drag_overlay.visible = true


func hide_drag_overlay() -> void:
	if _drag_overlay:
		_drag_overlay.visible = false


# ============================================================
#  动画
# ============================================================

func play_press_animation() -> void:
	if press_animation:
		press_animation.play()
	_play_press_sfx()


func play_release_animation() -> void:
	_apply_animation_params()
	if release_animation:
		release_animation.play()
	_play_release_sfx()


func play_consume_animation() -> void:
	# 订单消耗动画：取消选中 → 缩小消失 → 清空物品 + 恢复 scale
	if not item:
		scale = Vector2.ONE
		clear_item()
		return
	deselect()
	var center := size / 2.0
	pivot_offset = center
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.15)
	tween.tween_callback(_reset_after_consume)


func _reset_after_consume() -> void:
	scale = Vector2.ONE
	clear_item()


# ============================================================
#  音效（占位）
# ============================================================

func _play_press_sfx() -> void:
	pass


func _play_release_sfx() -> void:
	pass
