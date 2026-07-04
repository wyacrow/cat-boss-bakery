extends Control

# 测试场景脚本 - 设置默认物品

@onready var test_buttons: Array = [
	$TestContainer/ButtonRow1/TestButton1,
	$TestContainer/ButtonRow1/TestButton2,
	$TestContainer/ButtonRow1/TestButton3,
	$TestContainer/ButtonRow2/TestButton4,
	$TestContainer/ButtonRow2/TestButton5,
	$TestContainer/ButtonRow2/TestButton6
]

var cake_texture: Texture2D

func _ready() -> void:
	# 加载蛋糕图标
	cake_texture = load("res://cake.png")

	# 延迟一帧设置物品，确保所有按钮的 _ready() 已执行
	await get_tree().process_frame

	# 给第 2、3 个按钮设置测试物品（索引 1 和 2）
	for i in range(test_buttons.size()):
		var button: ItemCellButton = test_buttons[i]
		button.cell_position = Vector2i(i % 3, i / 3)  # 设置格子坐标

		if i == 1 or i == 2:
			# 创建测试物品
			var test_item = Item.new("bread", 1)
			test_item.texture = cake_texture
			button.set_item(test_item)
			print("TestSetup: Button", i+1, " set item: ", test_item)
		else:
			print("TestSetup: Button", i+1, " is empty")
