class_name Item
extends RefCounted

# Item - 物品数据类
# 定义物品的类型、等级和显示信息

var type: String = ""           # "bread" | "dessert" | "drink"
var level: int = 1              # 1~4
var texture: Texture2D = null   # 物品图标
var display_name: String = ""   # 显示名称


func _init(p_type: String = "", p_level: int = 1) -> void:
	type = p_type
	level = p_level
	_update_display_name()


func _update_display_name() -> void:
	# 根据 type 和 level 生成显示名称
	var type_names = {
		"bread": ["面粉", "面团", "面包", "高级面包"],
		"dessert": ["奶油", "奶油霜", "蛋糕", "高级蛋糕"],
		"drink": ["咖啡豆", "咖啡粉", "咖啡", "高级咖啡"]
	}

	if type in type_names:
		var names = type_names[type]
		if level >= 1 and level <= names.size():
			display_name = names[level - 1]
		else:
			display_name = "未知物品"
	else:
		display_name = "空物品"


func can_merge_with(other: Item) -> bool:
	# 判断是否可以合并（type 和 level 都相同）
	return type == other.type and level == other.level


func get_merge_result_level() -> int:
	# 获取合并后的等级（最高 Lv4）
	return min(level + 1, 4)


func is_max_level() -> bool:
	# 是否已达最高等级
	return level >= 4


func _to_string() -> String:
	return "Item(%s, Lv%d)" % [display_name, level]
