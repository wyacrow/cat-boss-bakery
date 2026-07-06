class_name GridBoard
extends PanelContainer

# ============================================================
#  GridBoard — 棋盘数据权威
#  从场景 GridContainer 动态读取行列数，响应 merge/move 信号，统一更新 UI
# ============================================================

var grid_cols: int = 0
var grid_rows: int = 0

var grid_data: Array = []          # Array[Array] of Item|null
var _cells: Array = []             # flat ItemCellButton refs
var _merge_system: MergeSystem
var _order_system: Node = null
var _generators: Dictionary = {}   # String -> GeneratorSystem（key 为 generator_type）
var _stamina: Node = null


## 返回当前棋盘上所有活跃生成器的物品类型列表
func get_active_item_types() -> Array[String]:
	var types: Array[String] = []
	for key in _generators:
		types.append(key)
	return types

# ── 生命周期 ──────────────────────────────────────────────

func _ready() -> void:
	_merge_system = MergeSystem.new()
	# 创建两个类型化生成器实例：饮品 + 面包
	_generators["drink"] = GeneratorSystem.new()
	_generators["drink"].generator_type = "drink"
	_generators["bread"] = GeneratorSystem.new()
	_generators["bread"].generator_type = "bread"
	_init_grid_data()
	_init_cells()


## 场景组装时注入体力系统引用
func set_stamina_system(node: Node) -> void:
	_stamina = node


## 场景组装时注入特效系统引用，分发给所有 cell
func set_effects_system(effects: EffectsSystem) -> void:
	for cell in _cells:
		cell.set_effects_system(effects)


## 场景组装时注入订单系统引用，用于 CheckIcon 刷新
func set_order_system(node: Node) -> void:
	_order_system = node
	_connect_check_signals()
	# 延迟刷新，等待 OrderSystem 加载完第一关的订单数据
	call_deferred("_refresh_check_icons")


func _connect_check_signals() -> void:
	if not EventBus.grid_changed.is_connected(_on_check_grid_changed):
		EventBus.grid_changed.connect(_on_check_grid_changed)
	if not EventBus.order_generated.is_connected(_on_check_order_generated):
		EventBus.order_generated.connect(_on_check_order_generated)
	if not EventBus.order_completed.is_connected(_on_check_order_completed):
		EventBus.order_completed.connect(_on_check_order_completed)
	if not EventBus.level_loaded.is_connected(_on_check_level_loaded):
		EventBus.level_loaded.connect(_on_check_level_loaded)


func _init_grid_data() -> void:
	var container := $GridContainer
	grid_cols = container.columns

	# 统计 ItemCellButton 数量，反推行数
	var cell_count := 0
	for child in container.get_children():
		if child is ItemCellButton:
			cell_count += 1
	grid_rows = ceili(float(cell_count) / grid_cols) if grid_cols > 0 else 0

	grid_data.clear()
	for row in range(grid_rows):
		grid_data.append([])
		for _col in range(grid_cols):
			grid_data[row].append(null)

	_place_initial_items()


func _place_initial_items() -> void:
	# ── 饮品链：Row 0 — drink Lv1, Lv1, Lv2, Lv1
	_place_item(0, 0, "drink", 1)
	_place_item(0, 1, "drink", 1)
	_place_item(0, 2, "drink", 2)
	_place_item(0, 3, "drink", 1)

	# ── 饮品链：Row 1 — drink Lv1, Lv1, Lv2
	_place_item(1, 0, "drink", 1)
	_place_item(1, 1, "drink", 1)
	_place_item(1, 2, "drink", 2)

	# ── 面包链：Row 2 — bread Lv1, Lv1, Lv2
	_place_item(2, 0, "bread", 1)
	_place_item(2, 1, "bread", 1)
	_place_item(2, 2, "bread", 2)

	# ── 面包链：Row 3 — bread Lv1, Lv1
	_place_item(3, 0, "bread", 1)
	_place_item(3, 1, "bread", 1)

	# 通知棋盘初始化完成
	var init_positions: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		Vector2i(0, 3), Vector2i(1, 3),
	]
	EventBus.grid_changed.emit(init_positions)


func _place_item(row: int, col: int, type: String, level: int) -> void:
	var it := Item.new(type, level)
	ResourceDB.apply_texture_to(it)
	_set_data(row, col, it)



func _set_data(row: int, col: int, it: Item) -> void:
	if row >= 0 and row < grid_rows and col >= 0 and col < grid_cols:
		grid_data[row][col] = it


func _init_cells() -> void:
	var container := $GridContainer
	var idx := 0

	for child in container.get_children():
		if not child is ItemCellButton:
			continue

		var cell: ItemCellButton = child
		var row := idx / grid_cols
		var col := idx % grid_cols
		cell.cell_position = Vector2i(col, row)

		# 应用初始数据
		if row < grid_rows and grid_data[row][col] != null:
			cell.set_item(grid_data[row][col])

		# 连接信号
		if cell.is_generator:
			cell.cell_pressed.connect(_on_generator_pressed.bind(cell.generator_type))
		else:
			cell.merge_request.connect(_on_merge_request)
			cell.move_request.connect(_on_move_request)

		_cells.append(cell)
		idx += 1


## 生成器格被点击 → 根据 generator_type 路由到对应 GeneratorSystem 实例
func _on_generator_pressed(pos: Vector2i, gen_type: String) -> void:
	AudioManager.play_sfx("bakery_basket_tap_rustle")
	try_generate_from(pos, gen_type)


## 公开生成入口：根据生成器类型调用对应 GeneratorSystem
## 流程：找空位 → 消耗体力 → 创建物品 → 立即预留目标格 → 投掷动画 → UI 更新 + 弹跳
func try_generate_from(from_pos: Vector2i, gen_type: String = "drink") -> bool:
	if _stamina == null:
		print("GridBoard: stamina system not set, generation failed")
		return false

	var gen: GeneratorSystem = _generators.get(gen_type, null)
	if gen == null:
		print("GridBoard: no generator for type '%s'" % gen_type)
		return false

	var result := gen.try_generate(self, _stamina, from_pos)
	if result.is_empty():
		AudioManager.play_sfx("board_full_meow")
		return false

	var item: Item = result["item"]
	var target: Vector2i = result["target"]

	# 立即预留目标格（防止快速连点时重复命中同一空格）
	set_item_at(target, item)

	AudioManager.play_sfx("bakery_item_spawn_plop")

	# 播放投掷预览动画（纯视觉，数据已就位）
	_play_throw_animation(from_pos, target, item)
	return true


## 播放投掷预览动画：从生成器格飞到目标空格
func _play_throw_animation(from_pos: Vector2i, to_pos: Vector2i, item: Item) -> void:
	var from_cell := get_cell_at(from_pos)
	var to_cell := get_cell_at(to_pos)
	if not from_cell or not to_cell:
		# 降级：直接放置
		_place_generated_item(to_pos, item)
		return

	# 预览图标大小与单元格一致
	var cell_size := from_cell.custom_minimum_size
	if cell_size == Vector2.ZERO:
		cell_size = from_cell.size

	# 创建临时预览 TextureRect
	var preview := TextureRect.new()
	preview.texture = item.texture
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = cell_size
	preview.size = cell_size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.top_level = true  # 使用屏幕坐标，不受父容器布局影响

	# 初始位置：生成器格中心
	var from_center := from_cell.global_position + from_cell.size / 2.0
	preview.position = from_center - cell_size / 2.0

	add_child(preview)

	# 目标位置：空格中心
	var to_center := to_cell.global_position + to_cell.size / 2.0
	var target_pos := to_center - cell_size / 2.0

	# 投掷动画：缓出（快速出发 → 缓慢抵达）
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(preview, "position", target_pos, 0.25)
	tween.tween_callback(_on_throw_arrive.bind(preview, to_pos, item))


## 投掷动画完成 → 清理预览 → 放置物品 + 弹跳动画
func _on_throw_arrive(preview: TextureRect, to_pos: Vector2i, item: Item) -> void:
	preview.queue_free()
	_place_generated_item(to_pos, item)


## 更新目标格 UI（数据已在 try_generate_from 中预留）
func _place_generated_item(to_pos: Vector2i, item: Item) -> void:
	var cell := get_cell_at(to_pos)
	if cell:
		cell.set_item(item)
		cell.play_release_animation()


## 从指定位置出发，找曼哈顿距离最近的空位
## 棋盘满时返回 Vector2i(-1, -1)
func find_nearest_empty(from_pos: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := 9999
	for row in range(grid_rows):
		for col in range(grid_cols):
			if grid_data[row][col] != null:
				continue
			var cell := get_cell_at(Vector2i(col, row))
			if cell and cell.is_generator:
				continue
			var dist: int = absi(row - from_pos.y) + absi(col - from_pos.x)
			if dist < best_dist:
				best_dist = dist
				best = Vector2i(col, row)
	return best


# ── 信号处理 ──────────────────────────────────────────────

func _on_merge_request(from_pos: Vector2i, to_pos: Vector2i) -> void:
	var from_item := get_item_at(from_pos)
	var to_item := get_item_at(to_pos)

	var merged := _merge_system.try_merge(from_item, to_item)
	if merged == null:
		return

	# 更新数据
	set_item_at(from_pos, null)
	set_item_at(to_pos, merged)

	# 更新 UI
	var from_cell := get_cell_at(from_pos)
	var to_cell := get_cell_at(to_pos)
	from_cell.clear_item()
	to_cell.set_item(merged)
	to_cell.select()
	to_cell.play_release_animation()
	EventBus.grid_changed.emit([from_pos, to_pos])
	EventBus.merge_done.emit(from_pos, to_pos, merged)


func _on_move_request(from_pos: Vector2i, to_pos: Vector2i) -> void:
	var from_item := get_item_at(from_pos)
	var to_item := get_item_at(to_pos)

	if to_item == null:
		# 移到空格：直接操作 + 弹跳动画
		_do_move_to_empty(from_pos, to_pos, from_item)
	else:
		# 交换：播放位移动画
		_play_swap_animation(from_pos, to_pos, from_item, to_item)


func _do_move_to_empty(from_pos: Vector2i, to_pos: Vector2i, from_item: Item) -> void:
	set_item_at(from_pos, null)
	set_item_at(to_pos, from_item)
	var from_cell := get_cell_at(from_pos)
	var to_cell := get_cell_at(to_pos)
	from_cell.clear_item()
	to_cell.set_item(from_item)
	to_cell.select()
	to_cell.play_release_animation()
	EventBus.grid_changed.emit([from_pos, to_pos])


## 交换动画：创建两个浮层预览 → 交叉飞向对方位置 → 交换数据 + 清理
func _play_swap_animation(from_pos: Vector2i, to_pos: Vector2i, from_item: Item, to_item: Item) -> void:
	var from_cell := get_cell_at(from_pos)
	var to_cell := get_cell_at(to_pos)
	if not from_cell or not to_cell:
		_do_swap_data(from_pos, to_pos, from_item, to_item)
		return

	var cell_size := from_cell.custom_minimum_size
	if cell_size == Vector2.ZERO:
		cell_size = from_cell.size

	var from_center := from_cell.global_position + from_cell.size / 2.0
	var to_center := to_cell.global_position + to_cell.size / 2.0

	# 创建两个浮层预览：from 物品在 from 位置，to 物品在 to 位置
	var preview_from := _make_floating_preview(from_item, cell_size, from_center)
	var preview_to := _make_floating_preview(to_item, cell_size, to_center)

	# 暂时隐藏原格图标（数据层不动，动画期间保持一致性）
	from_cell.clear_item()
	to_cell.clear_item()

	# 并行播放两个位移动画（交叉飞向对方位置）
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(preview_from, "position", to_center - cell_size / 2.0, 0.2)
	tween.tween_property(preview_to, "position", from_center - cell_size / 2.0, 0.2)

	# 动画完成后交换数据并清理
	tween.chain().tween_callback(_on_swap_complete.bind(
		preview_from, preview_to, from_pos, to_pos, from_item, to_item
	))


func _on_swap_complete(preview_from: TextureRect, preview_to: TextureRect,
		from_pos: Vector2i, to_pos: Vector2i,
		from_item: Item, to_item: Item) -> void:
	preview_from.queue_free()
	preview_to.queue_free()
	_do_swap_data(from_pos, to_pos, from_item, to_item)


func _do_swap_data(from_pos: Vector2i, to_pos: Vector2i, from_item: Item, to_item: Item) -> void:
	set_item_at(from_pos, to_item)
	set_item_at(to_pos, from_item)
	var from_cell := get_cell_at(from_pos)
	var to_cell := get_cell_at(to_pos)
	from_cell.set_item(to_item)
	to_cell.set_item(from_item)
	to_cell.select()
	EventBus.grid_changed.emit([from_pos, to_pos])


## 创建浮层预览 TextureRect（屏幕坐标，不受父容器布局影响）
func _make_floating_preview(item: Item, cell_size: Vector2, screen_center: Vector2) -> TextureRect:
	var preview := TextureRect.new()
	preview.texture = item.texture
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = cell_size
	preview.size = cell_size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.top_level = true
	preview.position = screen_center - cell_size / 2.0
	add_child(preview)
	return preview


# ── 数据访问 ──────────────────────────────────────────────

func get_cell_at(pos: Vector2i) -> ItemCellButton:
	var idx := pos.y * grid_cols + pos.x
	return _cells[idx] if idx >= 0 and idx < _cells.size() else null


func get_cell_global_center(pos: Vector2i) -> Vector2:
	var cell := get_cell_at(pos)
	if cell:
		return cell.global_position + cell.size / 2.0
	return Vector2.ZERO


func get_item_at(pos: Vector2i) -> Item:
	if pos.y < 0 or pos.y >= grid_rows or pos.x < 0 or pos.x >= grid_cols:
		return null
	return grid_data[pos.y][pos.x]


func set_item_at(pos: Vector2i, it: Item) -> void:
	if pos.y >= 0 and pos.y < grid_rows and pos.x >= 0 and pos.x < grid_cols:
		grid_data[pos.y][pos.x] = it


# ── 订单查询（直接扫描棋盘） ──────────────────────────────

## 检查棋盘上是否有足够物品满足订单需求
## requirements: {"bread_3": 1, "dessert_2": 2}
func has_items(requirements: Dictionary) -> bool:
	for key: String in requirements:
		var needed: int = requirements[key]
		var have: int = _count_on_grid(key)
		if have < needed:
			return false
	return true


## 从棋盘上扣除订单所需物品（先校验再调，顺序从右下开始避免空洞）
func remove_items(requirements: Dictionary) -> bool:
	if not has_items(requirements):
		return false

	var removed_positions: Array[Vector2i] = []
	for key: String in requirements:
		var needed: int = requirements[key]
		removed_positions.append_array(_remove_from_grid(key, needed))

	EventBus.grid_changed.emit(removed_positions)
	return true


## 统计棋盘上指定 type_level 的物品数量
func _count_on_grid(key: String) -> int:
	var parts := key.split("_")
	var item_type: String = parts[0]
	var item_level: int = int(parts[1])
	var count := 0
	for row in range(grid_rows):
		for col in range(grid_cols):
			var it: Item = grid_data[row][col]
			if it and it.type == item_type and it.level == item_level:
				count += 1
	return count


## 从棋盘移除指定数量的指定物品（从右下角开始扫描），返回被清除的位置列表
func _remove_from_grid(key: String, needed: int) -> Array[Vector2i]:
	var parts := key.split("_")
	var item_type: String = parts[0]
	var item_level: int = int(parts[1])
	var removed := 0
	var cleared: Array[Vector2i] = []
	# 从右下角开始，避免空洞影响视觉
	for row in range(grid_rows - 1, -1, -1):
		for col in range(grid_cols - 1, -1, -1):
			if removed >= needed:
				return cleared
			var it: Item = grid_data[row][col]
			if it and it.type == item_type and it.level == item_level:
				grid_data[row][col] = null
				var pos := Vector2i(col, row)
				cleared.append(pos)
				var cell := get_cell_at(pos)
				if cell:
					cell.play_consume_animation()
				removed += 1
	return cleared


# ═══════════════════════════════════════════════════════════════
#  CheckIcon 刷新
# ═══════════════════════════════════════════════════════════════

func _on_check_grid_changed(_positions: Array) -> void:
	_refresh_check_icons()


func _on_check_order_generated(_order) -> void:
	_refresh_check_icons()


func _on_check_order_completed(_order_id: String, _reward: int) -> void:
	_refresh_check_icons()


func _on_check_level_loaded(_level_id: String, _total: int) -> void:
	_refresh_check_icons()


## 遍历所有 cell：格内有物品且 {type}_{level} 出现在任意活跃订单需求中 → 显示 CheckIcon
func _refresh_check_icons() -> void:
	if _order_system == null:
		return

	# 收集当前活跃订单（屏幕中 2 个）的所有需求 key → Set
	var required_keys: Dictionary = {}
	var orders: Array = _order_system.get_orders()
	for order in orders:
		if order == null:
			continue
		for key: String in order.requirements:
			required_keys[key] = true

	# 遍历所有 cell，决定显示/隐藏
	# 注意：不能直接用 cell.item，因为消耗动画期间 cell.item 尚未清空
	# 必须以 grid_data（数据权威源）为准
	for cell in _cells:
		if cell.is_generator:
			cell.set_check_visible(false)
			continue
		var it: Item = get_item_at(cell.cell_position)
		if it == null:
			cell.set_check_visible(false)
			continue
		var item_key: String = it.type + "_" + str(it.level)
		cell.set_check_visible(required_keys.has(item_key))
