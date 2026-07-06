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

## 订单完成
signal order_completed(order_id: String, reward_gold: int)

## 新订单生成：order 为 OrderData 对象，包含 id/requirements/base_reward/customer_cat
signal order_generated(order)

## 金币变化
signal gold_changed(current: int)

## 订单完成进度变化：current=当前完成数，max_count=目标总数
signal order_progress_changed(current: int, max_count: int)

## 关卡完成：关卡内全部订单已完成
signal level_completed(level_id: String)

## 关卡加载：新关卡已加载
signal level_loaded(level_id: String, total_orders: int)

## 订单槽位释放：OrderBarManager 消失动画完成后发出，OrderSystem 监听后补入新订单
signal order_slot_freed()


func _ready() -> void:
	print("EventBus: autoload initialized, %d signals registered" % get_signal_list().size())
