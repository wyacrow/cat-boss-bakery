class_name RewardContainer
extends Control

# ============================================================
#  RewardContainer — 通用资源槽组件
#
#  结构（reward_container.tscn）：
#    RewardContainer (Control)
#    ├── Background (ColorRect)      — 半透明底板，铺满
#    ├── CurrencyIcon (TextureRect)  — 32×32 图标，左对齐、垂直居中
#    └── AmountLabel (Label)         — 文本，全局水平+垂直居中
#
#  用法：
#    setup("gold", 150)              → [💰] 150
#    setup("stamina", 0)             → [⚡] (仅设图标)
#    setup_stamina(15, 20)           → [⚡] 15/20
#    set_label_text("任意文字")
# ============================================================

# ── 导出属性 ──────────────────────────────────────────────

@export var bg_color: Color = Color(0, 0, 0, 0.3):
	set(value):
		bg_color = value
		if _bg:
			_bg.color = value

# ── 货币图标映射 ──────────────────────────────────────────

const CURRENCY_ICONS := {
	"gold": preload("res://sprites/gold.png"),
	"stamina": preload("res://sprites/food.png"),  # V1 占位，后续替换为闪电图标
}

# ── 子节点引用 ────────────────────────────────────────────

var _bg: ColorRect
var _icon: TextureRect
var _label: Label


# ============================================================
#  生命周期
# ============================================================

func _ready() -> void:
	_cache_children()
	if _bg:
		_bg.color = bg_color


func _cache_children() -> void:
	_bg = get_node_or_null("Background")
	_icon = get_node_or_null("CurrencyIcon")
	_label = get_node_or_null("AmountLabel")


# ============================================================
#  公开方法
# ============================================================

## 按货币类型初始化图标 + 数字显示
func setup(currency_type: String, amount: int) -> void:
	if _icon:
		if CURRENCY_ICONS.has(currency_type):
			_icon.texture = CURRENCY_ICONS[currency_type]
			_icon.visible = true
		else:
			_icon.visible = false
	if _label:
		_label.text = str(amount)


## 体力专用：图标 + "current/max" 格式
func setup_stamina(current: int, max_val: int) -> void:
	setup("stamina", 0)
	if _label:
		_label.text = "%d/%d" % [current, max_val]


## 直接设置标签文字（不改变图标）
func set_label_text(text: String) -> void:
	if _label:
		_label.text = text


## 仅更新数值
func set_amount(amount: int) -> void:
	if _label:
		_label.text = str(amount)


## 直接设置图标纹理
func set_icon_texture(texture: Texture2D) -> void:
	if _icon:
		_icon.texture = texture
		_icon.visible = true
