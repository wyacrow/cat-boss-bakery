@tool
extends Control

# GameScene - Main game scene
# V1 prototype: system wiring + layout + HUD binding

# === Preloads ===
const StaminaSystem := preload("res://scripts/systems/StaminaSystem.gd")
const BoardSkillSystemCls := preload("res://scripts/skills/BoardSkillSystem.gd")
const BoardSkillCls := preload("res://scripts/skills/BoardSkill.gd")
const ResourceDB := preload("res://scripts/data/ResourceDB.gd")
const LevelConfig := preload("res://scripts/data/LevelConfig.gd")

# === 统一配置变量 ===
@export var cell_button_size: Vector2 = Vector2(80, 80):
	set(value):
		cell_button_size = value
		if is_inside_tree():
			_apply_cell_button_size()

var _skill_system: Node = null
var _last_displayed_gold: int = 0

# ── 剧情标记 ──────────────────────────────────────────────
var _chapter1_played: bool = false

# ── 猫咪技能入口 ──────────────────────────────────────────
var _cat_click_count: int = 0
var _cat_last_click_time: float = 0.0
const CAT_PATIENCE_SEC: float = 1.0
const CAT_FURIOUS_CLICKS: int = 5

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	randomize()  # 初始化随机种子，确保每次运行结果不同
	print("GameScene loaded - wiring systems...")
	AudioManager.play_bgm("backGroundBG")
	_apply_cell_button_size()
	_wire_stamina_and_generator()
	_wire_order_system()
	_wire_effects_system()
	_wire_hud()
	_setup_skill_system()
	_setup_dialogue_flow()


# ── HUD 绑定 ──────────────────────────────────────────────

func _wire_hud() -> void:
	# 直接操作节点树中的 Label，不需要外部脚本
	var stamina_bar = get_node_or_null("MainVBox/AreaA_Top/TopHUDBar/HUDContainer/StaminaBar")
	var gold_bar = get_node_or_null("MainVBox/AreaA_Top/TopHUDBar/HUDContainer/GoldDisplay")

	if stamina_bar:
		var label := stamina_bar.get_node_or_null("Txt") as Label
		var stamina_sys := _find_stamina_system()
		if label and stamina_sys:
			label.text = "%d/%d" % [stamina_sys.get_stamina(), stamina_sys.get_max_stamina()]
			if not EventBus.stamina_changed.is_connected(_on_stamina_changed):
				EventBus.stamina_changed.connect(_on_stamina_changed.bind(label))
			print("GameScene: StaminaBar bound")

	if gold_bar:
		var label := gold_bar.get_node_or_null("Txt") as Label
		if label:
			_last_displayed_gold = GameStat.get_gold()
			label.text = str(_last_displayed_gold)
			if not EventBus.gold_changed.is_connected(_on_gold_changed):
				EventBus.gold_changed.connect(_on_gold_changed.bind(label))
			print("GameScene: GoldDisplay bound")


func _find_stamina_system() -> Node:
	for child in get_children():
		if child is StaminaSystem:
			return child
	return null


func _on_stamina_changed(current: int, max_stamina: int, label: Label) -> void:
	label.text = "%d/%d" % [current, max_stamina]


func _on_gold_changed(current: int, label: Label) -> void:
	var effects := $EffectsSystem as EffectsSystem
	if effects:
		effects.animate_number_tick(label, _last_displayed_gold, current)
	else:
		label.text = str(current)
	_last_displayed_gold = current


# ── 系统连线 ──────────────────────────────────────────────

func _wire_stamina_and_generator() -> void:
	# 创建 StaminaSystem 并注入到 GridBoard
	var stamina_sys := StaminaSystem.new()
	stamina_sys.name = "StaminaSystem"
	add_child(stamina_sys)

	var grid := _get_grid_board()
	grid.set_stamina_system(stamina_sys)
	print("GameScene: StaminaSystem created and injected into GridBoard")


func _wire_order_system() -> void:
	# 注入 GridBoard 到 OrderSystem
	var order_sys := $OrderSystem
	var grid := $MainVBox/AreaB_Grid/GridBoard
	order_sys.set_grid_board(grid)
	print("GameScene: GridBoard injected into OrderSystem")

	# 注入 OrderSystem 到 OrderBar + 动态挂载 OrderBarManager 脚本
	var order_bar := $MainVBox/AreaA_Top/OrderBar
	var manager_script := load("res://scripts/ui/components/order_bar_manager.gd")
	order_bar.set_script(manager_script)
	order_bar.setup(order_sys)
	print("GameScene: OrderBarManager setup complete")
	# 加载第一关订单
	order_sys.load_level(LevelConfig.get_first_level_id())

# OrderProgressBar 已直接在场景中，通过自身 _ready() 从 GameStat 自初始化


func _wire_effects_system() -> void:
	var effects := $EffectsSystem
	var gold_display := get_node_or_null("MainVBox/AreaA_Top/TopHUDBar/HUDContainer/GoldDisplay")
	var gold_label: Label = null
	if gold_display:
		gold_label = gold_display.get_node_or_null("Txt") as Label
	var order_bar := get_node_or_null("MainVBox/AreaA_Top/OrderBar")
	effects.setup(_get_grid_board(), gold_display, gold_label, order_bar)
	_get_grid_board().set_effects_system(effects)
	print("GameScene: EffectsSystem wired")


func _get_grid_board() -> Node:
	return $MainVBox/AreaB_Grid/GridBoard


func _apply_cell_button_size() -> void:
	# 遍历 GridContainer 下所有 Button 节点，统一设置大小
	var grid_container = $MainVBox/AreaB_Grid/GridBoard/GridContainer
	if grid_container:
		for child in grid_container.get_children():
			if child is Button:
				child.custom_minimum_size = cell_button_size


# ── 技能系统 ──────────────────────────────────────────────

func _setup_skill_system() -> void:
	# 创建技能系统并注入棋盘
	_skill_system = BoardSkillSystemCls.new()
	_skill_system.name = "BoardSkillSystem"
	add_child(_skill_system)
	_skill_system.setup(_get_grid_board())

	# 注册洗牌技能
	var shuffle_skill := BoardSkillCls.new(
		"shuffle",
		"猫咪 shuffle",
		"重新随机排列棋盘上的所有物品",
		3.0,
		_execute_shuffle
	)
	_skill_system.register_skill(shuffle_skill)

	# 注册清场技能
	var clear_skill := BoardSkillCls.new(
		"clear",
		"猫咪爆破",
		"将所有物品震飞出屏幕，清空棋盘",
		8.0,  # 较长冷却
		_execute_clear
	)
	_skill_system.register_skill(clear_skill)

	# 注册投掷技能
	var throw_skill := BoardSkillCls.new(
		"throw",
		"猫咪投掷",
		"从屏幕外投掷一个随机物品到空格子",
		2.0,
		_execute_throw
	)
	_skill_system.register_skill(throw_skill)
	print("GameScene: BoardSkillSystem initialized, 'shuffle' + 'clear' + 'throw' registered")
	_setup_cat_button()

func _setup_cat_button() -> void:
	var cat_grid := get_node_or_null("MainVBox/AreaA_Top/CatArea/catGrid")
	if not cat_grid:
		return

	# 透明按钮作为 catGrid 子节点，自动跟随 catGrid 位置和大小
	var btn := Button.new()
	btn.name = "CatSkillButton"
	btn.flat = true
	btn.anchors_preset = 15
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.pressed.connect(_on_cat_skill_pressed)
	cat_grid.add_child(btn)
	print("GameScene: CatSkillButton setup complete")


func _on_cat_skill_pressed() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _cat_last_click_time > CAT_PATIENCE_SEC:
		_cat_click_count = 0

	_cat_click_count += 1
	_cat_last_click_time = now

	var skill_id := _roll_cat_skill()
	print("GameScene: CatSkill click #%d -> %s" % [_cat_click_count, skill_id])

	# 先播放按钮动画，再执行技能
	_play_cat_button_animation(skill_id)
	_skill_system.use_skill(skill_id)


# ── 猫咪按钮技能动画 ──────────────────────────────────────

## 根据技能类型播放不同的按钮动画
func _play_cat_button_animation(skill_id: String) -> void:
	match skill_id:
		"throw":
			_animate_cat_vibrate()
		"shuffle":
			_animate_cat_sway()
		"clear":
			_animate_cat_explode()
		_:
			return


## 投掷 — 震荡动画：快速上下振动，模拟投掷反冲
func _animate_cat_vibrate() -> void:
	var cat := _get_cat_node()
	if not cat:
		return

	var original_pos: Vector2 = cat.position
	var amplitude := 8.0
	var duration := 0.35
	var steps := 8
	var step_dur := duration / steps

	var t := create_tween()
	for i in range(steps):
		var decay := 1.0 - float(i) / steps
		var offset_y := amplitude * decay * (1.0 if i % 2 == 0 else -1.0)
		t.tween_property(cat, "position:y", original_pos.y + offset_y, step_dur) \
			.set_trans(Tween.TRANS_LINEAR)
	# 归位
	t.tween_property(cat, "position", original_pos, step_dur * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 打乱 — 左右摇晃动画：像摇骰子一样左右摆动，逐渐衰减
func _animate_cat_sway() -> void:
	var cat := _get_cat_node()
	if not cat:
		return

	var original_pos: Vector2 = cat.position
	var amplitude := 18.0
	var duration := 0.55
	var steps := 6
	var step_dur := duration / steps

	var t := create_tween()
	for i in range(steps):
		var decay := 1.0 - float(i) / steps
		var sway_dir := 1.0 if i % 2 == 0 else -1.0
		t.tween_property(cat, "position:x", original_pos.x + sway_dir * amplitude * decay, step_dur) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	# 归位
	t.tween_property(cat, "position", original_pos, step_dur * 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 爆炸 — 上下左右 + 震荡混乱动画：全方向随机抖动，表现爆发混乱
func _animate_cat_explode() -> void:
	var cat := _get_cat_node()
	if not cat:
		return

	var original_pos: Vector2 = cat.position
	var amplitude := 20.0
	var duration := 0.7
	var steps := 12
	var step_dur := duration / steps

	# 预生成随机方向（上下左右 + 对角线），确保视觉混乱
	var dirs: Array[Vector2] = []
	for _i in range(steps):
		dirs.append(Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized())

	var t := create_tween()
	for i in range(steps):
		var decay := 1.0 - float(i) / steps
		var offset := dirs[i] * amplitude * decay
		t.tween_property(cat, "position", original_pos + offset, step_dur) \
			.set_trans(Tween.TRANS_LINEAR)
	# 归位
	t.tween_property(cat, "position", original_pos, step_dur * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 获取 catGrid 下的 cat TextureRect 节点
func _get_cat_node() -> Control:
	var cat_grid := get_node_or_null("MainVBox/AreaA_Top/CatArea/catGrid")
	if cat_grid:
		return cat_grid.get_node_or_null("cat") as Control
	return null


func _roll_cat_skill() -> String:
	if _cat_click_count >= CAT_FURIOUS_CLICKS:
		_cat_click_count = 0
		return "clear"

	var t := float(_cat_click_count - 1)
	var throw_p := maxf(0.20, 0.80 - t * 0.15)
	var clear_p := 0.02 + t * 0.04
	var shuffle_p := 1.0 - throw_p - clear_p

	var roll := randf()
	if roll < clear_p:
		return "clear"
	elif roll < clear_p + shuffle_p:
		return "shuffle"
	return "throw"



## 洗牌技能执行体
## 1. 收集所有非生成器格子（occupied + empty）和所有物品
## 2. 同时打乱物品顺序和位置顺序 → 物品随机散布到任意格子
## 3. 数据层更新 + 启动两阶段飞行动画
func _execute_shuffle(system: BoardSkillSystemCls, board: GridBoard) -> Array[Vector2i]:
	# 收集所有非生成器格子和物品
	var occupied := system.find_all_items()
	var empty := system.find_all_empty()

	if occupied.is_empty():
		return []

	# entries: 每个条目标记物品及其原始位置（动画起点）
	var entries: Array[Dictionary] = []
	for pos in occupied:
		entries.append({
			"item": board.get_item_at(pos),
			"old_pos": pos,
		})

	# 同时打乱：entries 顺序 + 空格子混入位置列表
	entries.shuffle()

	var all_positions: Array[Vector2i] = []
	all_positions.append_array(occupied)
	all_positions.append_array(empty)
	all_positions.shuffle()

	# 重新分配：前 N 个位置获得打乱后的物品，其余清空
	var changed: Array[Vector2i] = []
	var anim_pairs: Array[Dictionary] = []

	for i in range(all_positions.size()):
		var new_pos: Vector2i = all_positions[i]
		if i < entries.size():
			var entry: Dictionary = entries[i]
			board.set_item_at(new_pos, entry["item"])

			# 跳过原位不动的情况（避免无意义的自我飞行动画）
			if entry["old_pos"] != new_pos:
				anim_pairs.append({
					"from": entry["old_pos"],
					"to": new_pos,
					"item": entry["item"],
				})
		else:
			board.set_item_at(new_pos, null)

		changed.append(new_pos)

	# 启动飞行动画（数据已就位，动画纯视觉覆盖）
	system.animate_shuffle(anim_pairs)

	return changed


## 清场技能执行体
## 1. 收集所有物品及其位置
## 2. 数据层立即清空（生成器除外）
## 3. 启动爆散动画（纯视觉）
func _execute_clear(system: BoardSkillSystemCls, board: GridBoard) -> Array[Vector2i]:
	var positions := system.find_all_items()
	if positions.is_empty():
		return []

	# 收集物品（动画用）
	var items: Array = []
	for pos in positions:
		items.append(board.get_item_at(pos))

	# 数据层立即清空
	for pos in positions:
		board.set_item_at(pos, null)

	# 启动爆散动画
	system.animate_clear_board(positions, items)

	return positions


## 投掷技能执行体
## 1. 找随机空格 + 从棋盘活跃生成器类型池随机选类型（Lv1~3 随机）
## 2. 数据层立即放置
## 3. 启动投掷动画（从屏幕上方旋转飞入）
func _execute_throw(system: BoardSkillSystemCls, board: GridBoard) -> Array[Vector2i]:
	var empty := system.find_all_empty()
	if empty.is_empty():
		return []  # 没有空格

	# 随机选空格 + 从棋盘活跃类型池随机选物品类型
	var target: Vector2i = empty[randi() % empty.size()]
	var types: Array[String] = board.get_active_item_types()
	if types.is_empty():
		types = ["drink"]  # 兜底
	var item_type: String = types[randi() % types.size()]
	var level: int = randi_range(1, 3)  # Lv1~3 随机
	var item := Item.new(item_type, level)
	ResourceDB.apply_texture_to(item)  # 必须有纹理，预览才能显示

	# 数据层立即放置（预留目标格）
	board.set_item_at(target, item)

	# 启动投掷飞行动画
	system.animate_throw(target, item)

	return [target]

func _setup_dialogue_flow() -> void:
	# 序章：游戏启动后延迟 0.5s 播放
	await get_tree().create_timer(0.5).timeout
	var dp := get_node_or_null("/root/DialoguePlayer")
	if dp and dp.has_method("play"):
		dp.play("res://assets/scripts/prologue_street.json")
		print("GameScene: prologue dialogue triggered")

	# 监听第一关完成 → 播放第一章剧情
	if not EventBus.level_completed.is_connected(_on_level_completed):
		EventBus.level_completed.connect(_on_level_completed)
	print("GameScene: dialogue flow ready")

func _on_level_completed(level_id: String) -> void:
	if level_id != "level_01" or _chapter1_played:
		return
	_chapter1_played = true

	# 关卡完成后稍等半秒再弹剧情
	await get_tree().create_timer(0.5).timeout
	var dp := get_node_or_null("/root/DialoguePlayer")
	if dp and dp.has_method("play"):
		dp.play("res://assets/scripts/chapter1_strays.json")
		print("GameScene: chapter1 dialogue triggered")
