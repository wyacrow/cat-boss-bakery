class_name BoardSkillSystem
extends Node

# ============================================================
#  BoardSkillSystem — 棋盘技能框架
#
#  两大职责：
#    1. 原子操作层 —— 提供操纵 1~2 个格子的基础行为
#    2. 技能管理层 —— 注册、冷却、触发、通知
#
#  设计原则：
#    - 原子操作是棋盘变化的最小单元，不可再分
#    - 复杂技能通过组合原子操作实现（循环、条件、随机选格等）
#    - 每个原子操作同时更新数据层（grid_data）和表现层（cell UI）
#    - 技能执行完毕后统一发出一次 EventBus.grid_changed
#
#  原子操作分类：
#    ┌──────────┬────────────────────────────────────┐
#    │  单格    │ cell_upgrade  cell_remove          │
#    │          │ cell_place    cell_transform       │
#    ├──────────┼────────────────────────────────────┤
#    │  双格    │ cell_swap     cell_move            │
#    │          │ cell_merge                         │
#    └──────────┴────────────────────────────────────┘
#
#  用法示例（技能 Callable 内部）：
#    func _execute(system: BoardSkillSystem, board: GridBoard) -> Array[Vector2i]:
#        var changed: Array[Vector2i] = []
#        var candidates := system.find_all_items()
#        if candidates.is_empty():
#            return changed
#        # 随机选一个格子升级
#        var pos := candidates[randi() % candidates.size()]
#        changed.append_array(system.cell_upgrade(pos))
#        return changed
# ============================================================

const ResourceDB := preload("res://scripts/data/ResourceDB.gd")

# ── 棋盘引用 ──────────────────────────────────────────────

var board: GridBoard = null

# ── 技能注册表 ────────────────────────────────────────────

var _skills: Dictionary = {}       # {skill_id: BoardSkill}
var _cooldown_timers: Dictionary = {}  # {skill_id: float} 剩余冷却秒数


# of BoardSkillSystem.gd — 初始化 & 技能管理
# ═══════════════════════════════════════════════════════════


# ── 初始化 ──────────────────────────────────────────────────

func setup(p_board: GridBoard) -> void:
	board = p_board


func _process(delta: float) -> void:
	# 冷却计时
	for skill_id in _cooldown_timers.keys():
		var remaining: float = _cooldown_timers[skill_id]
		if remaining > 0.0:
			_cooldown_timers[skill_id] = max(0.0, remaining - delta)


# ── 技能管理 ────────────────────────────────────────────────

## 注册一个技能到系统中
func register_skill(skill: BoardSkill) -> void:
	_skills[skill.skill_id] = skill
	_cooldown_timers[skill.skill_id] = 0.0


## 移除技能注册
func unregister_skill(skill_id: String) -> void:
	_skills.erase(skill_id)
	_cooldown_timers.erase(skill_id)


## 触发指定技能。返回是否成功执行。
## 检查顺序：board 就绪 → 技能存在 → 冷却就绪 → 执行
func use_skill(skill_id: String) -> bool:
	if not board:
		push_error("BoardSkillSystem: board not set, call setup() first")
		return false

	if not _skills.has(skill_id):
		push_error("BoardSkillSystem: unknown skill '%s'" % skill_id)
		return false

	if not is_ready(skill_id):
		print("BoardSkillSystem: skill '%s' on cooldown (%.1fs remaining)" % [skill_id, get_cooldown_remaining(skill_id)])
		return false

	var skill: BoardSkill = _skills[skill_id]
	var changed: Array[Vector2i] = skill.execute(self, board)

	if changed.size() > 0:
		_cooldown_timers[skill_id] = skill.cooldown
		EventBus.grid_changed.emit(changed)
		print("BoardSkillSystem: skill '%s' executed, %d cells changed" % [skill_id, changed.size()])

	return changed.size() > 0


## 技能冷却是否已就绪
func is_ready(skill_id: String) -> bool:
	return _cooldown_timers.get(skill_id, 0.0) <= 0.0


## 获取指定技能的剩余冷却时间（秒）
func get_cooldown_remaining(skill_id: String) -> float:
	return _cooldown_timers.get(skill_id, 0.0)


## 获取技能实例
func get_skill(skill_id: String) -> BoardSkill:
	return _skills.get(skill_id, null)


## 获取所有已注册技能
func get_all_skills() -> Array[BoardSkill]:
	var result: Array[BoardSkill] = []
	for skill in _skills.values():
		result.append(skill)
	return result


# of BoardSkillSystem.gd — 原子操作（单格）
# ═══════════════════════════════════════════════════════════
#  每个原子操作返回 Array[Vector2i]：该操作影响的格子位置。
#  失败（条件不满足）返回空数组 []。
#  调用方负责收集所有返回值，最终统一通知 grid_changed。


## 升级指定格子的物品：等级 +1（等效于免费合成一次）
## - 空格 → 无效果，返回 []
## - Lv4 → 已达上限，返回 []
## - Lv1~3 → 提升 1 级，返回 [pos]
func cell_upgrade(pos: Vector2i) -> Array[Vector2i]:
	var item := board.get_item_at(pos)
	if item == null:
		return []
	if item.is_max_level():
		return []

	var new_item := Item.new(item.type, item.level + 1)
	ResourceDB.apply_texture_to(new_item)
	board.set_item_at(pos, new_item)

	var cell := board.get_cell_at(pos)
	if cell:
		cell.set_item(new_item)
		cell.play_release_animation()

	return [pos]


## 清除指定格子的物品
## - 空格/生成器格 → 无效果，返回 []
## - 有物品 → 清空，返回 [pos]
func cell_remove(pos: Vector2i) -> Array[Vector2i]:
	if _is_protected(pos):
		return []

	var item := board.get_item_at(pos)
	if item == null:
		return []

	board.set_item_at(pos, null)
	var cell := board.get_cell_at(pos)
	if cell:
		cell.clear_item()

	return [pos]


## 在指定位置放置物品（接受已有 Item 实例）
## - 目标格非空 → 无效果，返回 []
## - 目标格是生成器 → 无效果，返回 []
## - 空格 → 放置成功，返回 [pos]
func cell_place(pos: Vector2i, item: Item) -> Array[Vector2i]:
	if _is_protected(pos):
		return []
	if board.get_item_at(pos) != null:
		return []

	ResourceDB.apply_texture_to(item)
	board.set_item_at(pos, item)

	var cell := board.get_cell_at(pos)
	if cell:
		cell.set_item(item)
		cell.play_release_animation()

	return [pos]


## 在指定位置放置物品（便捷版：直接传 type + level，内部创建 Item）
func cell_place_new(pos: Vector2i, item_type: String, item_level: int = 1) -> Array[Vector2i]:
	return cell_place(pos, Item.new(item_type, item_level))


## 转化指定格子的物品类型（保持等级不变）
## - 空格 → 无效果，返回 []
## - 有物品 → type 变为 new_type，返回 [pos]
func cell_transform(pos: Vector2i, new_type: String) -> Array[Vector2i]:
	var item := board.get_item_at(pos)
	if item == null:
		return []
	if item.type == new_type:
		return []  # 类型相同，无需转化

	var new_item := Item.new(new_type, item.level)
	ResourceDB.apply_texture_to(new_item)
	board.set_item_at(pos, new_item)

	var cell := board.get_cell_at(pos)
	if cell:
		cell.set_item(new_item)
		cell.play_release_animation()

	return [pos]


# of BoardSkillSystem.gd — 原子操作（双格）
# ═══════════════════════════════════════════════════════════


## 交换两个格子的物品（纯位置交换，不检查是否可合成）
## - pos_a 和 pos_b 可以是空格（其中一个为空则等效于移动）
## - 不触发合成逻辑（如需合成请用 cell_merge）
func cell_swap(pos_a: Vector2i, pos_b: Vector2i) -> Array[Vector2i]:
	if _is_protected(pos_a) or _is_protected(pos_b):
		return []
	if pos_a == pos_b:
		return []

	var item_a := board.get_item_at(pos_a)
	var item_b := board.get_item_at(pos_b)

	# 两者都为空 → 无变化
	if item_a == null and item_b == null:
		return []

	# 数据层交换
	board.set_item_at(pos_a, item_b)
	board.set_item_at(pos_b, item_a)

	# 表现层同步
	var cell_a := board.get_cell_at(pos_a)
	var cell_b := board.get_cell_at(pos_b)
	if cell_a:
		if item_b:  cell_a.set_item(item_b)
		else:       cell_a.clear_item()
	if cell_b:
		if item_a:  cell_b.set_item(item_a)
		else:       cell_b.clear_item()

	return [pos_a, pos_b]


## 将物品从 from_pos 移动到 to_pos
## - to_pos 必须为空
## - from_pos 必须非空
## - from_pos 不能是生成器
func cell_move(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
	if _is_protected(from_pos) or _is_protected(to_pos):
		return []
	if from_pos == to_pos:
		return []

	var item := board.get_item_at(from_pos)
	if item == null:
		return []
	if board.get_item_at(to_pos) != null:
		return []  # 目标非空，不能移动

	# 数据层移动
	board.set_item_at(from_pos, null)
	board.set_item_at(to_pos, item)

	# 表现层同步
	var from_cell := board.get_cell_at(from_pos)
	var to_cell := board.get_cell_at(to_pos)
	if from_cell:
		from_cell.clear_item()
	if to_cell:
		to_cell.set_item(item)
		to_cell.play_release_animation()

	return [from_pos, to_pos]


## 尝试合成两个格子的物品（委托给 MergeSystem）
## - 两个物品 type 和 level 必须相同
## - from_pos 清空，to_pos 生成升级物品
## - 不可合成 → 返回 []
func cell_merge(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
	if _is_protected(from_pos) or _is_protected(to_pos):
		return []
	if from_pos == to_pos:
		return []

	var merge_sys := MergeSystem.new()
	var item_a := board.get_item_at(from_pos)
	var item_b := board.get_item_at(to_pos)

	var merged := merge_sys.try_merge(item_a, item_b)
	if merged == null:
		return []

	# 数据层：from 清空，to 升级
	board.set_item_at(from_pos, null)
	board.set_item_at(to_pos, merged)

	# 表现层同步
	var from_cell := board.get_cell_at(from_pos)
	var to_cell := board.get_cell_at(to_pos)
	if from_cell:
		from_cell.clear_item()
	if to_cell:
		to_cell.set_item(merged)
		to_cell.play_release_animation()

	return [from_pos, to_pos]


# of BoardSkillSystem.gd — 棋盘查询辅助
# ═══════════════════════════════════════════════════════════
#  这些方法供技能的 execute Callable 内部调用，
#  用于选定"哪些格子需要操作"，本身不修改棋盘状态。


## 获取棋盘上所有有物品的格子位置列表（排除生成器）
func find_all_items() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row in range(board.grid_rows):
		for col in range(board.grid_cols):
			var pos := Vector2i(col, row)
			if _is_protected(pos):
				continue
			if board.get_item_at(pos) != null:
				result.append(pos)
	return result


## 获取所有空格子位置列表（排除生成器）
func find_all_empty() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row in range(board.grid_rows):
		for col in range(board.grid_cols):
			var pos := Vector2i(col, row)
			if _is_protected(pos):
				continue
			if board.get_item_at(pos) == null:
				result.append(pos)
	return result


## 获取指定区域内所有有物品的格子（矩形区域，自动处理坐标顺序）
func find_items_in_rect(corner_a: Vector2i, corner_b: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var r0 := clampi(mini(corner_a.y, corner_b.y), 0, board.grid_rows - 1)
	var r1 := clampi(maxi(corner_a.y, corner_b.y), 0, board.grid_rows - 1)
	var c0 := clampi(mini(corner_a.x, corner_b.x), 0, board.grid_cols - 1)
	var c1 := clampi(maxi(corner_a.x, corner_b.x), 0, board.grid_cols - 1)

	for row in range(r0, r1 + 1):
		for col in range(c0, c1 + 1):
			var pos := Vector2i(col, row)
			if _is_protected(pos):
				continue
			if board.get_item_at(pos) != null:
				result.append(pos)
	return result


# of BoardSkillSystem.gd — 多格动画
# ═══════════════════════════════════════════════════════════

var _shuffle_ctx: Dictionary = {}  # 动画上下文（跨回调传递）


## 棋盘整体左右摇晃（可复用的通用动画）
## duration: 总时长（秒），amplitude: 最大偏移像素
func shake_board(duration: float = 0.25, amplitude: float = 10.0) -> void:
	var original_x := board.position.x
	var steps := 5
	var step_dur := duration / steps
	var t := create_tween()
	for i in range(steps):
		var decay := 1.0 - float(i) / steps
		var sign := 1.0 if i % 2 == 0 else -1.0
		t.tween_property(board, "position:x", original_x + sign * amplitude * decay, step_dur)
	t.tween_property(board, "position:x", original_x, step_dur * 0.5)  # 归位


## 播放洗牌飞行动画（三阶段：棋盘摇晃 → 散开 → 聚拢）
## anim_pairs: Array[Dictionary] — [{from: Vector2i, to: Vector2i, item: Item}]
## on_complete: 动画完成后的回调（无参数）
##
## 动画流程：
##   Phase 0「震」— 棋盘整体左右摇晃，发出技能触发的视觉信号
##   Phase 1「备」— 隐藏格子图标 + 在 from 位置创建浮动预览
##   Phase 2「散」— 预览同时向外随机散射
##   Phase 3「聚」— 预览逐个错开飞向目标位置
##   Phase 4「落」— 清除预览 + 恢复格子图标 + 目标格弹跳
func animate_shuffle(anim_pairs: Array, on_complete: Callable = Callable()) -> void:
	if anim_pairs.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return

	# 保存上下文供后续回调使用
	_shuffle_ctx["pairs"] = anim_pairs
	_shuffle_ctx["on_complete"] = on_complete

	# ── 主时间线 ──
	var master := create_tween()

	# Phase 0「震」— 棋盘摇晃 (0.25s)
	master.tween_callback(shake_board.bind(0.25, 10.0))
	master.tween_interval(0.28)

	# Phase 1「备」— 隐藏图标 + 创建浮动预览 + 启动后续阶段
	master.tween_callback(_prepare_shuffle_visual)


## Phase 1：隐藏格子图标 + 创建浮动预览 + 编排散→聚→落
func _prepare_shuffle_visual() -> void:
	var anim_pairs: Array = _shuffle_ctx["pairs"]
	var on_complete: Callable = _shuffle_ctx["on_complete"]

	# ── 隐藏所有受影响格子的图标，记录目标格 ──
	var hidden_cells: Array[ItemCellButton] = []
	var to_set: Dictionary = {}
	var hidden_set: Dictionary = {}
	for pair in anim_pairs:
		for key in ["from", "to"]:
			var pos: Vector2i = pair[key]
			var sid := "%d_%d" % [pos.x, pos.y]
			if key == "to":
				to_set[sid] = true
			if hidden_set.has(sid):
				continue
			hidden_set[sid] = true
			var cell := board.get_cell_at(pos)
			if cell and not cell.is_generator:
				hidden_cells.append(cell)
				cell.clear_item()

	# ── 创建浮动预览 ──
	var previews: Array[Dictionary] = []
	for pair in anim_pairs:
		var from_pos: Vector2i = pair["from"]
		var to_pos: Vector2i = pair["to"]
		var item: Item = pair["item"]

		var from_cell := board.get_cell_at(from_pos)
		var to_cell := board.get_cell_at(to_pos)
		if not from_cell or not to_cell:
			continue

		var cell_size := from_cell.custom_minimum_size
		if cell_size == Vector2.ZERO:
			cell_size = from_cell.size

		var from_center := from_cell.global_position + from_cell.size / 2.0
		var to_center := to_cell.global_position + to_cell.size / 2.0

		var preview := _make_skill_preview(item, cell_size, from_center)
		board.add_child(preview)

		var scatter_offset := Vector2(
			randf_range(-80.0, 80.0),
			randf_range(-80.0, 80.0)
		)

		previews.append({
			"preview": preview,
			"from_center": from_center,
			"scatter_pos": from_center + scatter_offset - cell_size / 2.0,
			"to_pos": to_center - cell_size / 2.0,
			"cell_size": cell_size,
		})

	# ── 编排后续阶段：散 → 聚 → 落 ──
	var seq := create_tween()

	seq.tween_callback(_start_scatter_phase.bind(previews))
	seq.tween_interval(0.22)

	seq.tween_callback(_start_fly_phase.bind(previews))
	var fly_total := (previews.size() - 1) * 0.03 + 0.40
	seq.tween_interval(fly_total)

	seq.tween_callback(_on_shuffle_finish.bind(previews, hidden_cells, to_set, on_complete))


## 洗牌动画完成 → 清除预览 → 恢复格子图标 → 仅目标格弹跳
func _on_shuffle_finish(previews: Array, hidden_cells: Array[ItemCellButton], to_set: Dictionary, on_complete: Callable) -> void:
	for p in previews:
		var pv: TextureRect = p["preview"]
		if is_instance_valid(pv):
			pv.queue_free()

	# 从数据层恢复格子图标（数据已在动画前更新完毕）
	for cell in hidden_cells:
		if not is_instance_valid(cell):
			continue
		var item := board.get_item_at(cell.cell_position)
		if item:
			cell.set_item(item)
		# 仅目标格（物品落点）播放弹跳动画
		var sid := "%d_%d" % [cell.cell_position.x, cell.cell_position.y]
		if to_set.has(sid):
			cell.play_release_animation()

	if on_complete.is_valid():
		on_complete.call()


## Phase A：所有预览同时向随机偏移位置散射
func _start_scatter_phase(previews: Array) -> void:
	var t := create_tween()
	t.set_parallel(true)
	for p in previews:
		var pv: TextureRect = p["preview"]
		t.tween_property(pv, "position", p["scatter_pos"], 0.2) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(pv, "scale", Vector2(0.85, 0.85), 0.2)


## Phase B：预览逐个错开飞向目标位置
func _start_fly_phase(previews: Array) -> void:
	for i in range(previews.size()):
		var p = previews[i]
		var pv: TextureRect = p["preview"]
		var stagger := i * 0.03

		var fly := create_tween()
		fly.tween_interval(stagger)
		fly.tween_property(pv, "position", p["to_pos"], 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		fly.parallel().tween_property(pv, "scale", Vector2(1.05, 1.05), 0.15)
		fly.tween_property(pv, "scale", Vector2(1.0, 1.0), 0.12)


# of BoardSkillSystem.gd — 清场动画
# ═══════════════════════════════════════════════════════════


## 清场动画：大震动 → 聚集中心 → 爆散飞出屏幕
## positions: 要清除的格子位置列表（数据层调用前应已清空）
## items: 对应位置的物品列表（用于预览显示，与 positions 一一对应）
## 动画是纯视觉表现，数据层由调用方在调用前处理
func animate_clear_board(positions: Array[Vector2i], items: Array, on_complete: Callable = Callable()) -> void:
	if positions.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return

	# ── 1. 隐藏所有物品格图标 ──
	var hidden_cells: Array[ItemCellButton] = []
	for pos in positions:
		var cell := board.get_cell_at(pos)
		if cell:
			hidden_cells.append(cell)
			cell.clear_item()

	# ── 2. 计算棋盘中心 ──
	var board_rect := board.get_global_rect()
	var center := board_rect.position + board_rect.size / 2.0

	# ── 3. 为每个物品创建预览 + 计算爆散方向 ──
	var previews: Array[Dictionary] = []
	for i in range(positions.size()):
		var pos: Vector2i = positions[i]
		var item: Item = items[i]
		var cell := board.get_cell_at(pos)
		if not cell:
			continue

		var cell_size := cell.custom_minimum_size
		if cell_size == Vector2.ZERO:
			cell_size = cell.size

		var cell_center := cell.global_position + cell.size / 2.0
		var preview := _make_skill_preview(item, cell_size, cell_center)
		board.add_child(preview)

		# 方向：中心 → 物品（径向向外），中心点物品给随机方向
		var dir := cell_center - center
		if dir.length() < 5.0:
			dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		dir = dir.normalized()

		# 目标点：沿方向延伸到屏幕外（加随机扰动避免完全共线）
		var fly_dist := 2500.0 + randf_range(-300.0, 300.0)
		var explode_target := center + dir * fly_dist

		# 每个物品随机旋转角度
		var spin := randf_range(-720.0, 720.0)

		previews.append({
			"preview": preview,
			"explode_target": explode_target,
			"rotation_deg": spin,
		})

	# ── 4. 主时间线：震 → 爆 → 清 ──
	var master := create_tween()

	# Phase 0「大震」— 棋盘剧烈摇晃 (0.5s)
	master.tween_callback(shake_board.bind(0.50, 22.0))
	master.tween_interval(0.55)

	# Phase 1「爆」— 从原位直接烟花式爆散
	master.tween_callback(_start_explode_phase.bind(previews))
	var explode_total := (previews.size() - 1) * 0.06 + 1.80
	master.tween_interval(explode_total)

	# Phase 2「清」— 清除预览 + 恢复空格显示
	master.tween_callback(_on_clear_finish.bind(previews, hidden_cells, on_complete))


## Phase 1「聚」：所有预览从原位吸向棋盘中心，缩小
func _start_gather_phase(previews: Array) -> void:
	var t := create_tween()
	t.set_parallel(true)
	for p in previews:
		var pv: TextureRect = p["preview"]
		t.tween_property(pv, "position", p["center_pos"], 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(pv, "scale", Vector2(0.5, 0.5), 0.35)


## Phase 2「爆」：从原位烟花式爆散 — 炸开 → 先快后慢飘出屏幕
func _start_explode_phase(previews: Array) -> void:
	for i in range(previews.size()):
		var p = previews[i]
		var pv: TextureRect = p["preview"]
		var stagger := i * 0.06

		var fly := create_tween()
		fly.tween_interval(stagger)

		# ① 炸开瞬间弹到 1.5 倍大（冲击力，0.15s）
		fly.tween_property(pv, "scale", Vector2(1.5, 1.5), 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# ② 三线并行：向外飘 + 缩小消失 + 自转（1.5s，速度减半）
		fly.tween_property(pv, "position", p["explode_target"], 1.5) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fly.parallel().tween_property(pv, "scale", Vector2(0.0, 0.0), 1.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fly.parallel().tween_property(pv, "rotation_degrees", p["rotation_deg"], 1.5)


## 清场完成 → 清除预览 → 恢复格子（数据层已由调用方清空）
func _on_clear_finish(previews: Array, hidden_cells: Array[ItemCellButton], on_complete: Callable) -> void:
	for p in previews:
		var pv: TextureRect = p["preview"]
		if is_instance_valid(pv):
			pv.queue_free()

	# 格子保持清空状态（数据已在动画前清空）
	for cell in hidden_cells:
		if is_instance_valid(cell):
			cell.clear_item()

	if on_complete.is_valid():
		on_complete.call()


# of BoardSkillSystem.gd — 投掷动画
# ═══════════════════════════════════════════════════════════


## 投掷动画：物品从屏幕上方旋转飞入，落到目标格子
## target_pos: 目标空格（数据层调用前应已放置物品）
## item: 要投掷的物品
func animate_throw(target_pos: Vector2i, item: Item, on_complete: Callable = Callable()) -> void:
	var target_cell := board.get_cell_at(target_pos)
	if not target_cell:
		if on_complete.is_valid():
			on_complete.call()
		return

	var cell_size := target_cell.custom_minimum_size
	if cell_size == Vector2.ZERO:
		cell_size = target_cell.size

	var target_center := target_cell.global_position + target_cell.size / 2.0

	# 起始位置：屏幕上方外，棋盘中心正上方
	var board_rect := board.get_global_rect()
	var start_center := Vector2(target_center.x, board_rect.position.y - 300.0)

	# 隐藏目标格图标（飞行动画期间）
	target_cell.clear_item()

	# 创建浮动预览
	var preview := _make_skill_preview(item, cell_size, start_center)
	preview.pivot_offset = cell_size / 4.0  # 锚点 = 左上角到中心的中点
	board.add_child(preview)
	preview.rotation_degrees = randf_range(-180.0, 180.0)  # 初始随机角度

	# 动画：边转边飞向目标
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(preview, "position", target_center - cell_size / 2.0, 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(preview, "rotation_degrees", preview.rotation_degrees + 720.0 * signf(randf() - 0.5), 0.6)

	# 落地后：清理预览 → 显示格子 → 弹跳
	t.chain().tween_callback(func():
		if is_instance_valid(preview):
			preview.queue_free()
		var cell := board.get_cell_at(target_pos)
		if cell:
			var data_item := board.get_item_at(target_pos)
			if data_item:
				cell.set_item(data_item)
			cell.play_release_animation()
		if on_complete.is_valid():
			on_complete.call()
	)


## 创建技能动画用的浮动预览 TextureRect
func _make_skill_preview(item: Item, cell_size: Vector2, screen_center: Vector2) -> TextureRect:
	var preview := TextureRect.new()
	preview.texture = item.texture
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.custom_minimum_size = cell_size
	preview.size = cell_size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.top_level = true
	preview.position = screen_center - cell_size / 2.0
	preview.z_index = 100
	return preview


# ── 内部 ──────────────────────────────────────────────────────

## 生成器格受保护，不允许技能操作
func _is_protected(pos: Vector2i) -> bool:
	var cell := board.get_cell_at(pos)
	return cell != null and cell.is_generator
