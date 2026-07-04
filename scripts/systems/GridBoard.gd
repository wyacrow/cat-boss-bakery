class_name GridBoard
extends PanelContainer

# ============================================================
#  GridBoard — 棋盘数据权威
#  持有 6×6 数据数组，响应 merge/move 信号，统一更新 UI
# ============================================================

const GRID_SIZE := 6

var grid_data: Array = []          # Array[Array] of Item|null
var _cells: Array = []             # flat ItemCellButton refs
var _merge_system: MergeSystem

# ── 生命周期 ──────────────────────────────────────────────

func _ready() -> void:
	_merge_system = MergeSystem.new()
	_init_grid_data()
	_init_cells()


func _init_grid_data() -> void:
	grid_data.clear()
	for row in range(GRID_SIZE):
		grid_data.append([])
		for _col in range(GRID_SIZE):
			grid_data[row].append(null)

	_place_initial_items()


func _place_initial_items() -> void:
	var tex := load("res://cake.png")

	# Row 0: bread 链  Lv1, Lv1, Lv2
	_set_data(0, 0, make_item("bread", 1, tex))
	_set_data(0, 1, make_item("bread", 1, tex))
	_set_data(0, 2, make_item("bread", 2, tex))

	# Row 1: dessert 链  Lv1, Lv1
	_set_data(1, 0, make_item("dessert", 1, tex))
	_set_data(1, 1, make_item("dessert", 1, tex))

	# Row 2: drink 链  Lv1, Lv1, Lv2
	_set_data(2, 0, make_item("drink", 1, tex))
	_set_data(2, 1, make_item("drink", 1, tex))
	_set_data(2, 2, make_item("drink", 2, tex))


func make_item(type: String, level: int, tex: Texture2D) -> Item:
	var it := Item.new(type, level)
	it.texture = tex
	return it


func _set_data(row: int, col: int, it: Item) -> void:
	grid_data[row][col] = it


# ── 初始化格子 ────────────────────────────────────────────

func _init_cells() -> void:
	var container := $GridContainer
	var idx := 0

	for child in container.get_children():
		if not child is ItemCellButton:
			continue

		var cell: ItemCellButton = child
		var row := idx / GRID_SIZE
		var col := idx % GRID_SIZE
		cell.cell_position = Vector2i(col, row)

		# 应用初始数据
		if grid_data[row][col] != null:
			cell.set_item(grid_data[row][col])

		# 连接信号
		cell.merge_request.connect(_on_merge_request)
		cell.move_request.connect(_on_move_request)

		_cells.append(cell)
		idx += 1


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


func _on_move_request(from_pos: Vector2i, to_pos: Vector2i) -> void:
	var from_item := get_item_at(from_pos)
	var to_item := get_item_at(to_pos)

	# 更新数据（交换）
	set_item_at(from_pos, to_item)
	set_item_at(to_pos, from_item)

	# 更新 UI
	var from_cell := get_cell_at(from_pos)
	var to_cell := get_cell_at(to_pos)
	from_cell.set_item(to_item)
	to_cell.set_item(from_item)

	# 移到空格 → 选中 + 动画；交换 → 选中
	if to_item == null:
		to_cell.select()
		to_cell.play_release_animation()
	else:
		to_cell.select()


# ── 数据访问 ──────────────────────────────────────────────

func get_cell_at(pos: Vector2i) -> ItemCellButton:
	var idx := pos.y * GRID_SIZE + pos.x
	return _cells[idx] if idx >= 0 and idx < _cells.size() else null


func get_item_at(pos: Vector2i) -> Item:
	if pos.y < 0 or pos.y >= GRID_SIZE or pos.x < 0 or pos.x >= GRID_SIZE:
		return null
	return grid_data[pos.y][pos.x]


func set_item_at(pos: Vector2i, it: Item) -> void:
	if pos.y >= 0 and pos.y < GRID_SIZE and pos.x >= 0 and pos.x < GRID_SIZE:
		grid_data[pos.y][pos.x] = it
