class_name StaminaSystem
extends Node
# StaminaSystem — 体力系统
# 最大体力 20，每 30 秒自动恢复 1 点。
# 猫咪 buff 可通过 regen_multiplier 修改恢复速度（工程猫 = 1.25 → 24s 恢复 1 点）。
#
# 对外接口：
#   consume(amount) -> bool  消耗体力，返回是否成功
#   recover(amount)          恢复体力（不会超过上限）
#   set_regen_multiplier(m)  设置恢复倍率（由 CatSystem 调用）
#   get_stamina() -> int     查询当前体力

@export var max_stamina: int = 20
@export var regen_interval: float = 30.0   # 基础恢复间隔（秒/点）

var current_stamina: int = 20
var regen_multiplier: float = 1.0           # 猫咪 buff 倍率，默认 1.0

var _regen_timer: Timer


func _ready() -> void:
	current_stamina = max_stamina
	_regen_timer = Timer.new()
	_regen_timer.one_shot = false
	_regen_timer.timeout.connect(_on_regen_tick)
	add_child(_regen_timer)
	_start_regen_timer()

	# 初始状态通知
	EventBus.stamina_changed.emit(current_stamina, max_stamina)
	print("StaminaSystem: initialized, stamina=%d/%d, interval=%.1fs" % [current_stamina, max_stamina, regen_interval])


# ── 公开方法 ──────────────────────────────────────────────────

func consume(amount: int) -> bool:
	if amount <= 0:
		return false
	if current_stamina >= amount:
		current_stamina -= amount
		EventBus.stamina_changed.emit(current_stamina, max_stamina)
		# 如果 timer 之前因满体力停止，消耗后重新启动
		if _regen_timer.is_stopped():
			_start_regen_timer()
		print("StaminaSystem: consumed %d, now %d/%d" % [amount, current_stamina, max_stamina])
		return true
	print("StaminaSystem: consume %d failed, only %d/%d" % [amount, current_stamina, max_stamina])
	return false


func recover(amount: int) -> void:
	if amount <= 0:
		return
	var old_stamina := current_stamina
	current_stamina = min(current_stamina + amount, max_stamina)
	if current_stamina != old_stamina:
		EventBus.stamina_changed.emit(current_stamina, max_stamina)
		print("StaminaSystem: recovered %d, now %d/%d" % [current_stamina - old_stamina, current_stamina, max_stamina])
	if current_stamina >= max_stamina:
		_regen_timer.stop()


func set_regen_multiplier(mult: float) -> void:
	var old_mult := regen_multiplier
	regen_multiplier = mult
	if regen_multiplier != old_mult and not _regen_timer.is_stopped():
		# 重新以新间隔启动 timer
		_start_regen_timer()
	print("StaminaSystem: regen_multiplier changed %.2f -> %.2f" % [old_mult, regen_multiplier])


func get_stamina() -> int:
	return current_stamina


func get_max_stamina() -> int:
	return max_stamina


# ── 内部 ──────────────────────────────────────────────────────

func _start_regen_timer() -> void:
	var interval := regen_interval / regen_multiplier
	_regen_timer.start(interval)


func _on_regen_tick() -> void:
	if current_stamina < max_stamina:
		current_stamina += 1
		EventBus.stamina_changed.emit(current_stamina, max_stamina)
		print("StaminaSystem: +1 regen, now %d/%d" % [current_stamina, max_stamina])
	if current_stamina >= max_stamina:
		_regen_timer.stop()
