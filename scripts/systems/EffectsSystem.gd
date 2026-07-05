class_name EffectsSystem
extends Node

# ============================================================
#  EffectsSystem — 游戏特效播放器
#  纯 EventBus 驱动（游戏事件）+ 直接调用（交互反馈）
#  与动画系统完全隔离，不修改任何游戏状态。
# ============================================================

const RING_GLOW_SHADER := preload("res://assets/shaders/ring_glow.gdshader")
const WHITE_TEX := preload("res://sprites/white_64.png")

var _grid_board: GridBoard = null

# ── 合并提示状态 ──────────────────────────────────────────

var _hint_pos: Vector2i = Vector2i(-1, -1)
var _hint_aura: TextureRect = null
var _hint_state: String = ""       # "" | "appearing" | "breathing" | "disappearing"

# ── 金币特效引用 ──────────────────────────────────────────

var _gold_display: Control = null
var _gold_label: Label = null
var _order_bar: Control = null


func setup(grid_board: GridBoard, gold_display: Control = null, gold_label: Label = null, order_bar: Control = null) -> void:
	_grid_board = grid_board
	_gold_display = gold_display
	_gold_label = gold_label
	_order_bar = order_bar
	if not EventBus.order_completed.is_connected(_on_order_completed_effect):
		EventBus.order_completed.connect(_on_order_completed_effect)


# ============================================================
#  合并提示 — 拖拽悬停可合成单元格时显示
# ============================================================

func show_merge_hint(at_pos: Vector2i, target_item: Item) -> void:
	# 同一格且正在显示 → no-op
	if _hint_pos == at_pos and _hint_state in ["appearing", "breathing"]:
		return

	# 正在消失中但拖回同一格 → 取消消失，从当前位置重新出现
	if _hint_pos == at_pos and _hint_state == "disappearing":
		_kill_all_tweens()
		_play_appear()
		return

	# 不同格子 / 无提示 → 立即清理旧提示，创建新的
	_kill_hint()

	_hint_pos = at_pos
	var center := _grid_board.get_cell_global_center(at_pos)

	# ShaderMaterial — 固定 scale_size，动画改由节点 scale 控制
	var mat := ShaderMaterial.new()
	mat.shader = RING_GLOW_SHADER
	var hint_color := _color_for_item(target_item)
	hint_color.a = 0.3
	mat.set_shader_parameter("base_color", hint_color)
	mat.set_shader_parameter("scale_size", 0.45)
	mat.set_shader_parameter("ring_base_radius", 0.25)
	mat.set_shader_parameter("ring_thickness", 0.05)
	mat.set_shader_parameter("fade_soft", 0.04)
	mat.set_shader_parameter("glow_power", 2.5)
	mat.set_shader_parameter("pulse_speed", 0.0)

	var cell_size := _estimate_cell_size()
	var size_val := cell_size * 2.0

	_hint_aura = TextureRect.new()
	_hint_aura.texture = WHITE_TEX
	_hint_aura.material = mat
	_hint_aura.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_hint_aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_aura.top_level = true
	_hint_aura.custom_minimum_size = Vector2(size_val, size_val)
	_hint_aura.size = Vector2(size_val, size_val)
	_hint_aura.position = center - _hint_aura.size / 2.0
	# 居中缩放原点：从中心向外扩张
	_hint_aura.pivot_offset = Vector2(size_val / 2.0, size_val / 2.0)
	_hint_aura.scale = Vector2.ZERO
	_hint_aura.modulate = Color(1.0, 1.0, 1.0, 0.0)

	add_child(_hint_aura)
	_play_appear()


func hide_any_hint() -> void:
	if _hint_state in ["appearing", "breathing"]:
		_play_disappear()


# ── 出现：从小 → 大 + 透明 → 不透明（先快后慢） ────────

func _play_appear() -> void:
	_hint_state = "appearing"

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_hint_aura, "scale", Vector2(2.0, 2.0), 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_hint_aura, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(_start_breathing)

	_hint_aura.set_meta("_tween", tween)


# ── 呼吸：微微缩放振荡 ──────────────────────────────────

func _start_breathing() -> void:
	if _hint_state != "appearing":
		return
	_hint_state = "breathing"

	var breath := create_tween()
	breath.set_loops()
	breath.tween_property(_hint_aura, "scale", Vector2(2.1, 2.1), 0.7)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breath.tween_property(_hint_aura, "scale", Vector2(2.0, 2.0), 0.7)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	_hint_aura.set_meta("_breath_tween", breath)


# ── 消失：大 → 小 + 淡出（先慢后快） ──────────────────

func _play_disappear() -> void:
	_hint_state = "disappearing"

	# 结束呼吸 tween
	_kill_tween_meta("_breath_tween")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_hint_aura, "scale", Vector2.ZERO, 0.12)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_hint_aura, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.12)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(_kill_hint)

	_hint_aura.set_meta("_tween", tween)


# ── 清理 ──────────────────────────────────────────────────

## 立即清除提示（不停留动画），用于快速切换格子
func _kill_hint() -> void:
	_kill_all_tweens()
	if _hint_aura:
		_hint_aura.queue_free()
	_hint_aura = null
	_hint_pos = Vector2i(-1, -1)
	_hint_state = ""


func _kill_all_tweens() -> void:
	if not _hint_aura:
		return
	_kill_tween_meta("_tween")
	_kill_tween_meta("_breath_tween")


func _kill_tween_meta(key: String) -> void:
	if not _hint_aura:
		return
	var t: Tween = _hint_aura.get_meta(key, null)
	if t and t.is_valid():
		t.kill()



# ============================================================
#  订单完成 — 金币爆散 + 吸收特效
# ============================================================

## 订单完成 → 金币从订单栏爆散 → 减速 → 逐个飞向金币显示区
func _on_order_completed_effect(_order_id: String, reward_gold: int) -> void:
	if not _order_bar or not _gold_display:
		return

	# 爆散起点：订单栏中心
	var from_pos := _order_bar.global_position + _order_bar.size * Vector2(0.5, 0.5)
	# 吸收终点：金币显示区域
	var to_pos := _gold_display.global_position + _gold_display.size * Vector2(0.5, 0.3)

	var coin_count := clampi(reward_gold / 5, 6, 16)
	_play_coin_burst(from_pos, to_pos, coin_count)

	# 浮字延迟到第一枚金币即将到达时出现（0.7 爆散 + 0.3 停顿 = 1.0s）
	var delay := create_tween()
	delay.tween_interval(1.0)
	delay.tween_callback(func(): _play_gold_float_text(to_pos, reward_gold))


## 金币爆散动画：从起点向四周爆散 → 减速到 0 → 逐个冲向目标点 + 缩小
## 总时长约 2s：
## - 阶段1 (burst): 0.7s, EASE_OUT（快起→减速到0）
## - 阶段2 (pause): 0.3s 停滞
## - 阶段3 (suck):  每枚金币间隔 0.05s 依次出发，单枚 0.65s, EASE_IN（慢起→加速冲向目标+缩小）
func _play_coin_burst(from_pos: Vector2, to_pos: Vector2, count: int) -> void:
	var coin_tex := ResourceDB.get_ui_texture("gold_icon")
	if not coin_tex:
		coin_tex = WHITE_TEX

	var coin_size := 56.0
	var stagger_per_coin := 0.05   # 每枚金币的出发间隔
	var suck_duration := 0.65      # 单枚金币冲向目标的时间

	for i in range(count):
		var coin := TextureRect.new()
		coin.texture = coin_tex
		coin.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.top_level = true
		coin.custom_minimum_size = Vector2(coin_size, coin_size)
		coin.position = from_pos - Vector2(coin_size / 2.0, coin_size / 2.0)
		coin.scale = Vector2.ONE
		# 随机微旋转让爆散看起来更自然
		coin.rotation = randf_range(-0.3, 0.3)
		add_child(coin)

		# 随机方向和距离
		var angle := randf() * TAU
		var dist := randf_range(90.0, 240.0)
		var burst_target := from_pos + Vector2(cos(angle), sin(angle)) * dist - Vector2(coin_size / 2.0, coin_size / 2.0)

		# 吸收终点偏移（加随机微调避免完全重叠）
		var jitter := Vector2(randf_range(-12.0, 12.0), randf_range(-6.0, 6.0))
		var suck_target := to_pos - Vector2(coin_size / 2.0, coin_size / 2.0) + jitter

		var tween := create_tween()
		# 阶段1: 爆散，EASE_OUT 模拟减速到 0
		tween.tween_property(coin, "position", burst_target, 0.7)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# 阶段2: 停滞 0.3s
		tween.tween_interval(0.3)
		# 阶段3: 按索引依次出发 → 先后顺序明确
		var my_stagger := i * stagger_per_coin
		if my_stagger > 0.0:
			tween.tween_interval(my_stagger)
		tween.set_parallel(true)
		tween.tween_property(coin, "position", suck_target, suck_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(coin, "scale", Vector2(0.2, 0.2), suck_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# 同时旋转归零
		tween.tween_property(coin, "rotation", 0.0, suck_duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# 清理
		tween.chain().tween_callback(_shake_gold_display)
		tween.chain().tween_callback(coin.queue_free)


# ============================================================
#  浮字特效 — "+N" 金币浮动文字
# ============================================================

## 在屏幕指定位置播放 "+N" 金币浮动文字动画
func _play_gold_float_text(global_pos: Vector2, amount: int) -> void:
	var label := Label.new()
	label.text = "+%d" % amount
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.top_level = true
	label.custom_minimum_size = Vector2(200, 80)
	label.position = global_pos - Vector2(100, 40)

	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	# 上升: 先快后慢
	tween.tween_property(label, "position:y", label.position.y - 140.0, 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 弹出: 0→1.25→1.0
	tween.tween_property(label, "scale", Vector2(1.25, 1.25), 0.12)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).set_delay(0.12)
	# 淡出: 后段消失
	tween.tween_property(label, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.7)

	tween.chain().tween_callback(label.queue_free)


# ============================================================
#  通用数字跳动动画 — 用于金币/体力等数值 Label
# ============================================================

## 对任意 Label 执行数字递增动画（例如金币从 100 跳到 150）
## 如果该 label 已有正在运行的跳动动画，会先终止再重新开始。
func animate_number_tick(label: Label, from_val: int, to_val: int, duration: float = 0.5) -> void:
	if not label:
		return

	# 终止该 label 上正在运行的跳动动画
	var existing: Tween = label.get_meta("_tick_tween", null)
	if existing and existing.is_valid():
		existing.kill()

	if from_val == to_val:
		label.text = str(to_val)
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(v: float): label.text = str(int(round(v))),
		float(from_val), float(to_val), duration
	)
	label.set_meta("_tick_tween", tween)


# ============================================================
#  金币框吸入震荡 — 每枚金币到达时触发
# ============================================================

## 对金币显示框播放一次短促的缩放震荡（1.0→1.15→0.95→1.0，共 0.2s）
## 连续吸入时自动终止上一次震荡并重新开始，形成密集的"叮叮"反馈感。
func _shake_gold_display() -> void:
	if not _gold_display:
		return

	# 终止上一次震荡（如果还在播放中）
	var existing: Tween = _gold_display.get_meta("_shake_tween", null)
	if existing and existing.is_valid():
		existing.kill()

	# 设置缩放锚点为中心
	_gold_display.pivot_offset = _gold_display.size / 2.0
	_gold_display.scale = Vector2.ONE

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_gold_display, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(_gold_display, "scale", Vector2(0.95, 0.95), 0.06)
	tween.tween_property(_gold_display, "scale", Vector2.ONE, 0.06)

	_gold_display.set_meta("_shake_tween", tween)


# ============================================================
#  视觉参数
# ============================================================

func _color_for_item(item: Item) -> Color:
	match item.type:
		"bread":   return Color(1.0, 0.55, 0.15, 1.0)
		"dessert": return Color(1.0, 0.25, 0.55, 1.0)
		"drink":   return Color(0.25, 0.55, 1.0, 1.0)
		_:         return Color(1.0, 1.0, 1.0, 1.0)


func _estimate_cell_size() -> float:
	if _grid_board:
		var cell := _grid_board.get_cell_at(Vector2i.ZERO)
		if cell:
			return cell.size.x
	return 175.0
