class_name BoardSkill
extends RefCounted

# ============================================================
#  BoardSkill — 棋盘技能数据类
#
#  封装技能的元数据和执行逻辑。
#  执行逻辑通过 Callable 注入，内部调用 BoardSkillSystem 的原子操作。
#  复杂技能 = 多个原子操作的组合（循环/条件/随机选格等）。
#
#  Callable 签名：
#    func(system: BoardSkillSystem, board: GridBoard) -> Array[Vector2i]
#    参数1 — system：调用原子操作（cell_swap / cell_upgrade / …）
#    参数2 — board：查询棋盘状态（get_item_at / find_nearest_empty / …）
#    返回值 — 所有受影响的格子位置，用于最终 grid_changed 通知
# ============================================================

var skill_id: String = ""
var display_name: String = ""
var description: String = ""
var cooldown: float = 0.0   # 冷却时间（秒）

## Callable: func(BoardSkillSystem, GridBoard) -> Array[Vector2i]
var _execute: Callable


func _init(p_id: String = "", p_name: String = "", p_desc: String = "",
		p_cooldown: float = 0.0, p_execute: Callable = Callable()) -> void:
	skill_id = p_id
	display_name = p_name
	description = p_desc
	cooldown = p_cooldown
	_execute = p_execute


## 执行技能逻辑，返回受影响的格子位置列表
func execute(system: BoardSkillSystem, board: GridBoard) -> Array[Vector2i]:
	if _execute.is_valid():
		return _execute.call(system, board)
	return []


func _to_string() -> String:
	return "BoardSkill(%s, cd=%.1fs)" % [skill_id, cooldown]
