@tool
extends Control

# GameScene - Main game scene
# V1 prototype: system wiring + layout + HUD binding

# === Preloads ===
const StaminaSystem := preload("res://scripts/systems/StaminaSystem.gd")
const BoardSkillSystemCls := preload("res://scripts/skills/BoardSkillSystem.gd")
const BoardSkillCls := preload("res://scripts/skills/BoardSkill.gd")
const ResourceDB := preload("res://scripts/data/ResourceDB.gd")

# === 统一配置变量 ===
@export var cell_button_size: Vector2 = Vector2(80, 80):
	set(value):
		cell_button_size = value
		if is_inside_tree():
			_apply_cell_button_size()

var _skill_system: Node = null
var _last_displayed_gold: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	randomize()  # 初始化随机种子，确保每次运行结果不同
	print("GameScene loaded - wiring systems...")
	_apply_cell_button_size()
	_wire_stamina_and_generator()
	_wire_order_system()
	_wire_effects_system()
	_wire_order_progress()
	_wire_hud()
	_setup_skill_system()


# ── HUD 绑定 ──────────────────────────────────────────────

func _wire_hud() -> void:
	# 直接操作节点树中的 Label，不需要外部脚本
	var stamina_bar = get_node_or_null("MainVBox/AreaA_Top/TopHUDBar/HUDContainer/StaminaBar")
	var gold_bar = get_node_or_null("MainVBox/AreaA_Top/TopHUDBar/HUDContainer/GoldDisplay")

	if stamina_bar:
		var label := stamina_bar.get_node_or_null("CurrencyContainer/Txt") as Label
		var stamina_sys := _find_stamina_system()
		if label and stamina_sys:
			label.text = "%d/%d" % [stamina_sys.get_stamina(), stamina_sys.get_max_stamina()]
			if not EventBus.stamina_changed.is_connected(_on_stamina_changed):
				EventBus.stamina_changed.connect(_on_stamina_changed.bind(label))
			print("GameScene: StaminaBar bound")

	if gold_bar:
		var label := gold_bar.get_node_or_null("CurrencyContainer/Txt") as Label
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

func _wire_order_progress() -> void:
	var order_bar := $MainVBox/AreaA_Top/OrderBar
	var progress_bar := preload("res://scenes/ui/order_progress_bar.tscn").instantiate()
	progress_bar.name = "OrderProgressBar"
	progress_bar.anchor_top = 0.0
	progress_bar.anchor_bottom = 0.2
	progress_bar.anchor_left = 0.0
	progress_bar.anchor_right = 0.0
	progress_bar.offset_left = 20.0
	progress_bar.offset_right = 280.0
	progress_bar.offset_top = 20.0
	progress_bar.offset_bottom = 0.0
	order_bar.add_child(progress_bar)
	progress_bar.set_initial(GameStat.max_orders_target, GameStat.orders_completed)
	print("GameScene: OrderProgressBar wired, target=%d" % GameStat.max_orders_target)


func _wire_effects_system() -> void:
	var effects := $EffectsSystem
	var gold_display := get_node_or_null("MainVBox/AreaA_Top/TopHUDBar/HUDContainer/GoldDisplay")
	var gold_label: Label = null
	if gold_display:
		gold_label = gold_display.get_node_or_null("CurrencyContainer/Txt") as Label
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

	# 在 CatArea 中创建一排测试按钮
	_create_skill_buttons()


func _create_skill_buttons() -> void:
	var cat_area := get_node_or_null("MainVBox/AreaA_Top/CatArea")
	if not cat_area:
		return

	# 隐藏原有的 TextureButton
	var old_btn := cat_area.get_node_or_null("TextureButton")
	if old_btn:
		old_btn.visible = false

	# 创建水平容器
	var hbox := HBoxContainer.new()
	hbox.name = "SkillButtons"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	cat_area.add_child(hbox)

	# 定义按钮列表：{text, skill_id, color}
	var buttons := [
		{"text": "洗牌", "skill": "shuffle", "color": Color(0.3, 0.6, 0.9, 1.0)},
		{"text": "爆破", "skill": "clear",  "color": Color(0.9, 0.3, 0.3, 1.0)},
		{"text": "投掷", "skill": "throw",  "color": Color(0.3, 0.8, 0.4, 1.0)},
		{"text": "震动", "skill": "",      "color": Color(0.6, 0.5, 0.2, 1.0)},
	]

	for cfg in buttons:
		var btn := Button.new()
		btn.text = cfg["text"]
		btn.custom_minimum_size = Vector2(120, 60)

		# 按钮样式
		var style := StyleBoxFlat.new()
		style.bg_color = cfg["color"]
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal", style)

		# 文字样式
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 22)

		var skill_id: String = cfg["skill"]
		if skill_id.is_empty():
			btn.pressed.connect(_on_shake_only_pressed)
		else:
			btn.pressed.connect(_on_skill_btn_pressed.bind(skill_id))

		hbox.add_child(btn)

	print("GameScene: 4 skill test buttons created")


func _on_skill_btn_pressed(skill_id: String) -> void:
	_skill_system.use_skill(skill_id)


func _on_shake_only_pressed() -> void:
	_skill_system.shake_board(0.50, 22.0)


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
## 1. 找随机空格 + 随机生成 Lv1 物品
## 2. 数据层立即放置
## 3. 启动投掷动画（从屏幕上方旋转飞入）
func _execute_throw(system: BoardSkillSystemCls, board: GridBoard) -> Array[Vector2i]:
	var empty := system.find_all_empty()
	if empty.is_empty():
		return []  # 没有空格

	# 随机选空格 + 随机物品类型
	var target: Vector2i = empty[randi() % empty.size()]
	var types := ["bread", "dessert", "drink"]
	var item_type: String = types[randi() % types.size()]
	var item := Item.new(item_type, 1)
	ResourceDB.apply_texture_to(item)  # 必须有纹理，预览才能显示

	# 数据层立即放置（预留目标格）
	board.set_item_at(target, item)

	# 启动投掷飞行动画
	system.animate_throw(target, item)

	return [target]
