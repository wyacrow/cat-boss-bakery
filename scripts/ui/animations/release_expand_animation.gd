class_name ReleaseExpandAnimation
extends ButtonAnimation

# 弹起弹性震荡动画：1.0 → 1.3 → 0.9 → 1.0
# 三段震荡，后面回弹加快

var scale_peak: float = 1.3    # 第一波峰值
var scale_dip: float = 0.9     # 第二波谷值
var scale_final: float = 1.0   # 最终回到原比例


func _init() -> void:
	# 三段震荡总时长
	duration = 0.3
	transition = Tween.TRANS_QUAD
	ease = Tween.EASE_OUT


func play() -> void:
	if not _is_target_valid():
		return

	print("DEBUG ReleaseExpand: 3-stage bounce ", target.name)

	# 设置缩放锚点为中心
	var center = target.size / 2.0
	target.pivot_offset = center

	# 三段动画：放大→缩小→恢复，后面两段加快
	var tween = _create_tween()
	if tween:
		# 第一段：放大到峰值（40% 时长，较慢）
		tween.tween_property(target, "scale", Vector2(scale_peak, scale_peak), duration * 0.4)
		# 第二段：缩小到谷值（30% 时长，加快）
		tween.tween_property(target, "scale", Vector2(scale_dip, scale_dip), duration * 0.3)
		# 第三段：恢复到原比例（30% 时长，加快）
		tween.tween_property(target, "scale", Vector2(scale_final, scale_final), duration * 0.3)
