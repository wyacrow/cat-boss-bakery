class_name ButtonAnimation
extends RefCounted

# 动画基类 - 所有按钮动画的父类
# 支持曲线控制，即插即用

var target: Control = null
var duration: float = 0.1
var transition: Tween.TransitionType = Tween.TRANS_LINEAR
var ease: Tween.EaseType = Tween.EASE_IN_OUT

var _tween: Tween = null


func play() -> void:
	# 抽象方法，子类实现具体动画逻辑
	pass


func stop() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null


func _create_tween() -> Tween:
	# 创建 Tween 并应用曲线设置
	stop()  # 停止之前的动画

	if not _is_target_valid():
		print("DEBUG ButtonAnimation: target is null or invalid!")
		return null

	_tween = target.create_tween()
	_tween.set_trans(transition)
	_tween.set_ease(ease)
	print("DEBUG ButtonAnimation: created tween for ", target.name, " trans=", transition, " ease=", ease)
	return _tween


func _is_target_valid() -> bool:
	return target != null and is_instance_valid(target)
