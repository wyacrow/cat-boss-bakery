class_name OrderSlot
extends TextureRect

const ResourceDB := preload("res://scripts/data/ResourceDB.gd")

# ============================================================
#  OrderSlot — 订单槽位 UI 组件
#
#  订单最多包含 2 种物品需求，一一对应场景中的两个预建 ItemBtn。
#  不使用 clone 方案，ItemBtn/ItemBtn2 直接显示/隐藏。
#
#  结构（与 order_slot.tscn 预制体一致）：
#    OrderSlot (ColorRect)
#    ├── CatIcon (TextureRect)
#    ├── ItemContainer (Control)
#    │   ├── ItemBtn (Control)              — 第 1 个需求槽（预建）
#    │   │   ├── ItemTexture (TextureRect)  — 背景框
#    │   │   │   └── ContentIcon            — 物品内容图
#    │   │   └── ItemCountLabel (Label)     — 数量 "×N"
#    │   └── ItemBtn2 (Control)             — 第 2 个需求槽（预建）
#    │       ├── ItemTexture (TextureRect)  — 背景框
#    │       │   └── ContentIcon            — 物品内容图
#    │       └── ItemCountLabel (Label)     — 数量 "×N"
#    ├── RewardBtn (Control)
#    │   └── CurrencySet
#    │       ├── CurrencyIcon (TextureRect)
#    │       └── Label
#    ├── CatIcon (TextureRect)
#    └── AnimationPlayer
#
#  交互：点击卡片 → order_system.submit_order(order_id)
# ============================================================

# ── 信号 ──────────────────────────────────────────────────

signal slot_pressed(slot_index: int)
signal disappear_finished()

# ── 公开属性 ──────────────────────────────────────────────

var slot_index: int = -1
var order_id: String = ""
var is_empty: bool = true

## 系统引用（由父级注入）
var order_system: Node = null

# ── 预建需求槽位引用 ──────────────────────────────────────

var _item_slot1: Control = null     # ItemContainer/ItemBtn
var _item_slot2: Control = null     # ItemContainer/ItemBtn2

# ── 其他子节点引用 ────────────────────────────────────────

var _cat_icon: TextureRect
var _gold_icon: TextureRect
var _reward_label: Label

# ── 标签样式缓存 ──────────────────────────────────────────

var _label_font_size: int = 43
var _label_font_color: Color = Color(0.5647, 0.2863, 0.098, 1.0)


# ============================================================
#  生命周期
# ============================================================

func _ready() -> void:
	_cache_children()
	_listen_events()
	_update_visual()
	_setup_click_area()


func _cache_children() -> void:
	_cat_icon = get_node_or_null("CatIcon")

	# 两个预建需求槽位（不再 clone，直接引用）
	_item_slot1 = get_node_or_null("ItemContainer/ItemBtn")
	_item_slot2 = get_node_or_null("ItemContainer/ItemBtn2")

	# 默认隐藏两个槽位，有订单时按需显示
	if _item_slot1:
		_item_slot1.visible = false
		_item_slot1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 读取标签样式
		var lbl := _item_slot1.get_node_or_null("ItemCountLabel") as Label
		if lbl and lbl.label_settings:
			_label_font_size = lbl.label_settings.font_size
			_label_font_color = lbl.label_settings.font_color

	if _item_slot2:
		_item_slot2.visible = false
		_item_slot2.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 金币区
	var reward_btn := get_node_or_null("RewardBtn")
	if reward_btn:
		var currency_set := reward_btn.get_node_or_null("CurrencySet")
		if currency_set:
			_gold_icon = currency_set.get_node_or_null("CurrencyIcon")
			_reward_label = currency_set.get_node_or_null("Label")


func _listen_events() -> void:
	gui_input.connect(_on_gui_input)


func _setup_click_area() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ============================================================
#  公开方法
# ============================================================

func set_order_system(sys: Node) -> void:
	order_system = sys


## 以 OrderData 对象设置订单（最多 2 种物品需求）
func set_order(order) -> void:
	order_id = order.id
	is_empty = false
	_update_requirements(order.requirements)
	_update_reward(order.base_reward)
	_update_cat(order.customer_cat)
	_update_visual()


func clear_order() -> void:
	order_id = ""
	is_empty = true
	_hide_all_slots()
	if _reward_label:
		_reward_label.text = ""
	_update_visual()


# ============================================================
#  需求槽位更新
# ============================================================

## 根据订单需求显示/隐藏 ItemBtn / ItemBtn2
## requirements: {"drink_2": 2, "bread_3": 1}  — 最多 2 个 key
func _update_requirements(requirements: Dictionary) -> void:
	_hide_all_slots()

	var keys: Array = requirements.keys()
	var count: int = min(keys.size(), 2)

	for i in range(count):
		var key: String = keys[i]
		var parts: PackedStringArray = key.split("_")
		var item_type: String = parts[0]
		var item_level: int = int(parts[1])
		var quantity: int = requirements[key]

		var slot: Control = _item_slot1 if i == 0 else _item_slot2
		if not slot:
			continue

		slot.visible = true

		# ContentIcon = 物品内容图
		var icon := slot.get_node_or_null("ItemTexture/ContentIcon") as TextureRect
		if icon:
			var tex := ResourceDB.get_item_texture_by_parts(item_type, item_level)
			if tex:
				icon.texture = tex

		# 数量标签
		var label := slot.get_node_or_null("ItemCountLabel") as Label
		if label:
			label.text = "×%d" % quantity


func _hide_all_slots() -> void:
	if _item_slot1:
		_item_slot1.visible = false
	if _item_slot2:
		_item_slot2.visible = false


# ============================================================
#  其他视觉更新
# ============================================================

func _update_reward(reward: int) -> void:
	if _reward_label:
		_reward_label.text = str(reward)


func _update_cat(cat_type: String) -> void:
	if _cat_icon:
		if is_empty or cat_type == "":
			_cat_icon.visible = false
		else:
			var tex := ResourceDB.get_customer_cat_texture(cat_type)
			if tex:
				_cat_icon.texture = tex
			_cat_icon.visible = true


func _update_visual() -> void:
	if is_empty:
		modulate = Color(1.0, 1.0, 1.0, 0.5)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)


# ============================================================
#  交互处理
# ============================================================

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if is_empty:
		return
	play_shake_animation()
	AudioManager.play_sfx("order_ready_meow")
	_submit()


func _submit() -> void:
	if order_system == null:
		print("OrderSlot: cannot submit — order_system not set")
		return

	var ok: bool = order_system.submit_order(order_id)
	if ok:
		print("OrderSlot: order '%s' submitted successfully" % order_id)
	else:
		print("OrderSlot: order '%s' submission failed" % order_id)


# ============================================================
#  动画方法
# ============================================================

func animate_appear(duration: float = 0.2) -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = Vector2(0.85, 0.85)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color.WHITE, duration)
	tween.tween_property(self, "scale", Vector2.ONE, duration)


func animate_disappear(duration: float = 0.25) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), duration)
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), duration)
	tween.chain().tween_callback(func():
		disappear_finished.emit()
	)


func animate_to_position(target_pos: Vector2, duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_pos, duration)


func play_shake_animation(duration: float = 0.3) -> void:
	pivot_offset = size / 2.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), duration * 0.4)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), duration * 0.3)
	tween.tween_property(self, "scale", Vector2.ONE, duration * 0.3)


# ============================================================
#  外部纹理设置（由父级按 idx 注入）
# ============================================================

func set_item_texture_at(idx: int, texture: Texture2D) -> void:
	var slot: Control = _item_slot1 if idx == 0 else _item_slot2
	if not slot:
		return
	var icon := slot.get_node_or_null("ItemTexture/ContentIcon") as TextureRect
	if icon:
		icon.texture = texture


func set_cat_texture(texture: Texture2D) -> void:
	if _cat_icon:
		_cat_icon.texture = texture


func set_gold_icon_texture(texture: Texture2D) -> void:
	if _gold_icon:
		_gold_icon.texture = texture
