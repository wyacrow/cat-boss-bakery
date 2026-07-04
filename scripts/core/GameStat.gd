extends Node
# GameStat — 全局玩家数据 (Autoload)
# V1: 仅追踪金币。后续版本可扩展更多字段（钻石、完成订单数、游戏时长等）。
#
# 对外接口：
#   add_gold(amount)         增加金币，发出 gold_changed
#   spend_gold(amount) -> bool  消费金币，成功发出 gold_changed
#   get_gold() -> int        查询当前金币

var gold: int = 0


func _ready() -> void:
	# 监听订单完成 → 自动加金币
	EventBus.order_completed.connect(_on_order_completed)
	print("GameStat: initialized, gold=%d" % gold)


# ── 公开方法 ──────────────────────────────────────────────────

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	EventBus.gold_changed.emit(gold)
	print("GameStat: +%d gold, now %d" % [amount, gold])


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	if gold >= amount:
		gold -= amount
		EventBus.gold_changed.emit(gold)
		print("GameStat: -%d gold, now %d" % [amount, gold])
		return true
	print("GameStat: spend %d failed, only %d gold" % [amount, gold])
	return false


func get_gold() -> int:
	return gold


# ── 信号响应 ──────────────────────────────────────────────────

func _on_order_completed(_order_id: String, reward_gold: int) -> void:
	add_gold(reward_gold)
