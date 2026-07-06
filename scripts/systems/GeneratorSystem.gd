class_name GeneratorSystem
extends RefCounted

# ============================================================
#  GeneratorSystem — 生成器（浪漫餐厅模式）
#
#  由生成器按钮触发 → 消耗 1 体力 → 生成指定类型 Lv1 物品
#  → 返回数据供 GridBoard 播放投掷动画后放置。
#
#  通过 generator_type 属性区分产出类型（drink/bread/dessert）
#
#  用法：
#    var gen = GeneratorSystem.new()
#    gen.generator_type = "bread"
#    var result = gen.try_generate(board, stamina, from_pos)
#    result == {}     → 体力不足或棋盘已满
#    result != {}     → {"item": Item, "target": Vector2i} 供调用方播放动画后放置
# ============================================================

var generator_type: String = "drink"  # 产出物品类型（默认饮品）
const ResourceDB := preload("res://scripts/data/ResourceDB.gd")


## 找最近空位 + 消耗体力 + 创建 Lv1 物品 → 返回 {item, target} 供调用方播放投掷动画后放置
func try_generate(board: GridBoard, stamina: Node, from_pos: Vector2i) -> Dictionary:
	# 1. 找最近空位
	var target := board.find_nearest_empty(from_pos)
	if target.x < 0:
		print("GeneratorSystem[%s]: grid is full, generation failed" % generator_type)
		return {}

	# 2. 消耗体力
	if not stamina.consume(1):
		print("GeneratorSystem[%s]: stamina insufficient, generation failed" % generator_type)
		return {}

	# 3. 创建指定类型 Lv1 物品
	var item := Item.new(generator_type, 1)
	ResourceDB.apply_texture_to(item)

	print("GeneratorSystem[%s]: generated %s Lv1 for target (%d,%d)" % [generator_type, generator_type, target.x, target.y])
	return {"item": item, "target": target}
