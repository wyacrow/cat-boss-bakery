@tool
extends Control

# GameScene - Main game scene placeholder
# V1 prototype: layout verification only, no game logic yet

# === 统一配置变量 ===
@export var cell_button_size: Vector2 = Vector2(80, 80):
	set(value):
		cell_button_size = value
		_apply_cell_button_size()

func _ready() -> void:
	print("GameScene loaded - layout prototype")
	_apply_cell_button_size()

func _apply_cell_button_size() -> void:
	# 遍历 GridContainer 下所有 Button 节点，统一设置大小
	var grid_container = $MainVBox/AreaB_Grid/GridBoard/GridContainer
	if grid_container:
		for child in grid_container.get_children():
			if child is Button:
				child.custom_minimum_size = cell_button_size
