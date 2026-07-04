extends Control

# 简单的 StarBurstEffect 演示场景脚本
# 点击屏幕任意位置触发特效
# 用法：将此脚本挂载到 Control 根节点，然后将 star_burst.tscn 拖入 fx_scene 导出变量

const FX_SCENE_PATH := "res://scenes/effects/star_burst.tscn"

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_fx(event.global_position)

func _spawn_fx(at_pos: Vector2) -> void:
	var scene := load(FX_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Failed to load: ", FX_SCENE_PATH)
		return
	var fx := scene.instantiate() as StarBurstEffect
	if fx == null:
		push_error("Scene root is not StarBurstEffect")
		return
	add_child(fx)
	fx.play(at_pos)
