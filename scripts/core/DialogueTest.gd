extends Control
# DialogueTest — 对话系统测试场景
# 用法：直接运行 scenes/test/dialogue_test.tscn


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# 等待一帧确保所有 autoload 就绪，然后自动播放测试剧本
	await get_tree().process_frame
	_play_dialogue()
	print("DialogueTest: triggered sample dialogue")


func _input(event: InputEvent) -> void:
	# 按空格键重新播放
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_play_dialogue()


func _play_dialogue() -> void:
	# 运行时查找 autoload，避免编译期依赖
	var player := get_node_or_null("/root/DialoguePlayer")
	if player and player.has_method("play"):
		player.play("res://assets/scripts/chapter1_strays.json")
	else:
		push_error("DialogueTest: DialoguePlayer autoload not found!")
