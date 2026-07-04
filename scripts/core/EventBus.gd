extends Node
# EventBus — 全局信号总线 (Autoload)
# 所有系统间的通信都通过 EventBus 信号进行，禁止系统间直接调用方法。
#
# 信号签名与 cat_bakery_merge_design.md §四 完全一致。

## 体力变化：每次 current_stamina 改变时发出
signal stamina_changed(current: int, max_stamina: int)

## 棋盘变化：positions 为发生变化的格子坐标列表
signal grid_changed(positions: Array)

## 合成完成：from_pos 被清空，to_pos 生成 result_item
signal merge_done(from_pos: Vector2i, to_pos: Vector2i, result_item)

## 库存变化：added_items 和 removed_items 为变化的 Item 数组
signal inventory_changed(added_items: Array, removed_items: Array)

## 订单完成
signal order_completed(order_id: String, reward_gold: int)

## 新订单生成：requirements 格式 {"bread_3": 1, "dessert_2": 2}
signal order_generated(order_id: String, requirements: Dictionary)

## 收取请求：三击后由 CollectSystem 发出
signal collect_request(item, from_pos: Vector2i)

## 收取成功：InventorySystem 确认入库后发出
signal collect_done(item, from_pos: Vector2i)

## 收取失败：reason 如 "inventory_full"
signal collect_failed(reason: String)

## 自动合成开关切换
signal auto_merge_toggled(enabled: bool)

## 金币变化
signal gold_changed(current: int)


func _ready() -> void:
	print("EventBus: autoload initialized, %d signals registered" % get_signal_list().size())
