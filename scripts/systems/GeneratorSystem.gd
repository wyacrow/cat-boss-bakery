class_name GeneratorSystem
extends RefCounted

# ============================================================
#  GeneratorSystem — 生成器（浪漫餐厅模式）
#
#  由生成器按钮触发 → 消耗 1 体力 → 随机 Lv1 物品
#  → 返回数据供 GridBoard 播放投掷动画后放置。
#
#  三种原料等概率（33%/33%/33%）：bread / dessert / drink
#
#  用法：
#    var result = gen.try_generate(board, stamina, from_pos)
#    result == {}     → 体力不足或棋盘已满
#    result != {}     → {"item": Item, "target": Vector2i} 供调用方播放动画后放置
# ============================================================

const ITEM_TYPES := ["drink"]  # 咖啡专链（临时，V1 原型验证用）
const ResourceDB := preload("res://scripts/data/ResourceDB.gd")


## 找最近空位 + 消耗体力 + 创建 Lv1 物品 → 返回 {item, target} 供调用方播放投掷动画后放置
func try_generate(board: GridBoard, stamina: Node, from_pos: Vector2i) -> Dictionary:
	# 1. 找最近空位
	var target := board.find_nearest_empty(from_pos)
	if target.x < 0:
		print("GeneratorSystem: grid is full, generation failed")
		return {}

	# 2. 消耗体力
	if not stamina.consume(1):
		print("GeneratorSystem: stamina insufficient, generation failed")
		return {}

	# 3. 随机选 type（33/33/33）
	var item_type: String = ITEM_TYPES[randi() % ITEM_TYPES.size()]

	# 4. 创建 Lv1 物品（交由调用方播放动画后放置）
	var item := Item.new(item_type, 1)
	ResourceDB.apply_texture_to(item)

	print("GeneratorSystem: generated %s Lv1 for target (%d,%d)" % [item_type, target.x, target.y])
	return {"item": item, "target": target}
