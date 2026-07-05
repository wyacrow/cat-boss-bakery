extends CanvasLayer
# Accessed globally via autoload name "DialoguePlayer"
#
# UI 布局定义在 scenes/ui/dialogue_player.tscn 中，可在编辑器内可视编辑。

# ============================================================
#  DialoguePlayer — 剧情对话表现器 (Autoload)
#
#  外部调用：DialoguePlayer.play("path/to/script.json")
#  播完发出：dialogue_finished(script_path)
#
#  布局：全屏半透明遮罩 + 底部40%对话框区 + 左右人物立绘
# ============================================================

# ── 信号 ──────────────────────────────────────────────────

signal dialogue_finished(script_path: String)

# ── 常量 ──────────────────────────────────────────────────

const TYPING_SPEED: float = 0.04
const FADE_DURATION: float = 0.3

# ── 状态 ──────────────────────────────────────────────────

var _script_path: String = ""
var _lines: Array = []
var _characters: Dictionary = {}
var _line_index: int = 0
var _is_typing: bool = false
var _full_text: String = ""
var _typed_count: int = 0
var _type_timer: float = 0.0
var _is_transitioning: bool = false

# ── 节点引用（在 _ready 中绑定） ──────────────────────────

@onready var _root: Control = $Root
@onready var _left_slot: Control = $Root/BottomArea/HBox/LeftSlot
@onready var _right_slot: Control = $Root/BottomArea/HBox/RightSlot
@onready var _left_portrait: TextureRect = $Root/BottomArea/HBox/LeftSlot/TextureRect
@onready var _right_portrait: TextureRect = $Root/BottomArea/HBox/RightSlot/TextureRect
@onready var _name_label: Label = $Root/BottomArea/HBox/Center/NameLabel
@onready var _dialog_text: Label = $Root/BottomArea/HBox/Center/Panel/DialogText
@onready var _click_area: Control = $Root/ClickArea


# ============================================================
#  初始化
# ============================================================

func _ready() -> void:
	_click_area.gui_input.connect(_on_gui_input)
	visible = false
	print("DialoguePlayer: autoload initialized")


# ============================================================
#  公开 API
# ============================================================

func play(script_path: String) -> void:
	if _is_transitioning:
		push_warning("DialoguePlayer: already playing or transitioning, ignoring play(%s)" % script_path)
		return

	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		push_error("DialoguePlayer: cannot open script: %s" % script_path)
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_error("DialoguePlayer: JSON parse error in %s: %s" % [script_path, json.get_error_message()])
		return

	var data: Dictionary = json.get_data()
	_lines = data.get("lines", [])
	_characters = data.get("characters", {})
	_script_path = script_path
	_line_index = 0

	# 入场
	_root.modulate = Color.WHITE
	visible = true
	_is_transitioning = false

	print("DialoguePlayer: playing %s (%d lines)" % [script_path, _lines.size()])
	_show_line(0)


# ============================================================
#  内部逻辑
# ============================================================

func _show_line(index: int) -> void:
	if index >= _lines.size():
		_finish()
		return

	var line: Dictionary = _lines[index]
	var char_id: String = line.get("character_id", "")
	var position: String = line.get("position", "center")
	var text: String = line.get("text", "")
	# sfx 占位，V1 不处理

	# 角色信息
	var char_info: Dictionary = _characters.get(char_id, {})
	var display_name: String = char_info.get("name", char_id)
	# 立绘路径：逐行覆盖 > 角色默认
	var portrait_path: String = line.get("portrait", char_info.get("portrait", ""))

	# 名字（位置跟随说话者）
	_name_label.text = display_name if display_name != "" else ""
	_name_label.visible = display_name != ""
	match position:
		"left":
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		"right":
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_:
			_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 立绘 & 占位槽显隐
	var show_left: bool = (position == "left")
	var show_right: bool = (position == "right")

	_left_slot.visible = show_left
	_right_slot.visible = show_right
	_left_portrait.visible = show_left
	_right_portrait.visible = show_right

	if show_left and portrait_path != "":
		_left_portrait.texture = _safe_load(portrait_path)
	if show_right and portrait_path != "":
		_right_portrait.texture = _safe_load(portrait_path)

	# 打字机
	_full_text = text
	_typed_count = 0
	_is_typing = true
	_type_timer = 0.0
	_dialog_text.text = ""


func _safe_load(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if res is Texture2D:
			return res
	return null


# ============================================================
#  打字机 & 输入
# ============================================================

func _process(delta: float) -> void:
	if not _is_typing:
		return

	_type_timer += delta
	while _type_timer >= TYPING_SPEED and _typed_count < _full_text.length():
		_type_timer -= TYPING_SPEED
		_typed_count += 1
		_dialog_text.text = _full_text.substr(0, _typed_count)

	if _typed_count >= _full_text.length():
		_is_typing = false


func _on_gui_input(event: InputEvent) -> void:
	if not visible or _is_transitioning:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_typing:
			# 打字中 → 立即显示完整句
			_dialog_text.text = _full_text
			_is_typing = false
		else:
			# 已完成 → 下一句
			_line_index += 1
			_show_line(_line_index)


# ============================================================
#  结束
# ============================================================

func _finish() -> void:
	_is_transitioning = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate", Color(1, 1, 1, 0), FADE_DURATION)
	tween.tween_callback(_on_fade_done)


func _on_fade_done() -> void:
	visible = false
	_root.modulate = Color.WHITE
	_is_transitioning = false

	# 清理：释放立绘纹理引用
	_left_portrait.texture = null
	_right_portrait.texture = null

	dialogue_finished.emit(_script_path)
	print("DialoguePlayer: finished %s" % _script_path)
