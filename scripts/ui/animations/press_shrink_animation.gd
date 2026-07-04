class_name PressShrinkAnimation
extends ButtonAnimation

# 按下缩放动画：1.0 → 0.9
# 默认使用 Quad 过渡 + EaseIn 曲线（快速响应）

var scale_from: float = 1.0
var scale_to: float = 0.9


func _init() -> void:
	# 默认配置：快速缩小的按下反馈
	duration = 0.08
	transition = Tween.TRANS_QUAD
	ease = Tween.EASE_IN


func play() -> void:
	if not _is_target_valid():
		print("DEBUG PressShrink: target invalid!")
		return

	print("DEBUG PressShrink: scaling ", target.name, " from ", scale_from, " to ", scale_to)
	var tween = _create_tween()
	if tween:
		tween.tween_property(target, "scale", Vector2(scale_to, scale_to), duration)
