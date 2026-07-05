class_name OrderProgressBar
extends Control

# ============================================================
#  OrderProgressBar — 订单完成进度条
#  监听 EventBus.order_progress_changed，带动画填充。
#  视觉由 order_progress_bar.tscn 预制体决定。
# ============================================================

var _max_count: int = 10
var _current: int = 0
var _fill_bar: ColorRect = null
var _label: Label = null
var _tween: Tween = null


func _ready() -> void:
	_fill_bar = get_node_or_null("FillBar") as ColorRect
	_label = get_node_or_null("ProgressLabel") as Label

	if not EventBus.order_progress_changed.is_connected(_on_progress_changed):
		EventBus.order_progress_changed.connect(_on_progress_changed)


func _on_progress_changed(current: int, max_count: int) -> void:
	_max_count = max_count

	var from_ratio: float = float(_current) / float(_max_count) if _max_count > 0 else 0.0
	var to_ratio: float = float(current) / float(_max_count) if _max_count > 0 else 0.0

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_method(_update_fill, from_ratio, to_ratio, 0.5)

	_current = current


func _update_fill(ratio: float) -> void:
	if _fill_bar:
		_fill_bar.anchor_right = ratio
	if _label:
		_label.text = "%d/%d" % [_current, _max_count]


func set_initial(max_count: int, current: int = 0) -> void:
	_max_count = max_count
	_current = current
	if _fill_bar:
		_fill_bar.anchor_right = float(current) / float(max_count) if max_count > 0 else 0.0
	if _label:
		_label.text = "%d/%d" % [current, max_count]
