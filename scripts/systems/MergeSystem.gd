class_name MergeSystem
extends RefCounted

# ============================================================
#  MergeSystem — 合成逻辑处理器
#  纯数据层，不触碰 UI
# ============================================================

func try_merge(item_a: Item, item_b: Item) -> Item:
	if item_a == null or item_b == null:
		return null
	if not item_a.can_merge_with(item_b):
		return null
	if item_a.is_max_level():
		return null

	var merged := Item.new(item_a.type, item_a.get_merge_result_level())
	merged.texture = item_a.texture  # TODO: 替换为对应等级的贴图
	return merged
