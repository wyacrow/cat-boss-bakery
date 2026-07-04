@tool
extends GPUParticles2D
class_name StarBurstEffect

# ============================================================
#  StarBurstEffect — 合成成功星星爆发特效
#
#  使用方法：
#    StarBurstEffect.spawn(global_position, self)
#
#  视觉特点：
#    - 40-60 颗星形粒子从中心 360° 爆发
#    - 金色→白色→透明的渐变
#    - 粒子自旋 + 径向向外 + 阻尼减速
#    - 生命周期末尾平滑渐隐
#    - 播放完成后自动 queue_free
# ============================================================

const SCENE_PATH := "res://scenes/effects/star_burst.tscn"

# ── 发射参数 ────────────────────────────────────────────────

@export_group("Emission", "burst_")
@export_range(10, 200) var burst_count: int = 50:
	set(v):
		burst_count = v
		if is_inside_tree():
			amount = v
@export_range(0.2, 2.0) var burst_lifetime: float = 0.7:
	set(v):
		burst_lifetime = v
		if is_inside_tree():
			lifetime = v

# ── 速度与运动 ──────────────────────────────────────────────

@export_group("Velocity", "vel_")
@export_range(50.0, 400.0) var vel_min: float = 100.0
@export_range(50.0, 400.0) var vel_max: float = 180.0
@export_range(0.0, 200.0) var vel_damping_min: float = 30.0
@export_range(0.0, 200.0) var vel_damping_max: float = 60.0
@export_range(-400.0, 400.0) var vel_radial_min: float = -120.0
@export_range(-400.0, 400.0) var vel_radial_max: float = -180.0

# ── 旋转 ────────────────────────────────────────────────────

@export_group("Rotation", "rot_")
@export_range(-1440.0, 1440.0) var rot_angular_min: float = -540.0
@export_range(-1440.0, 1440.0) var rot_angular_max: float = 540.0
@export_range(-180.0, 180.0) var rot_angle_min: float = -180.0
@export_range(-180.0, 180.0) var rot_angle_max: float = 180.0

# ── 缩放 ────────────────────────────────────────────────────

@export_group("Scale", "scale_")
@export_range(0.1, 2.0) var scale_initial_min: float = 0.6
@export_range(0.1, 2.0) var scale_initial_max: float = 1.0

# ── 颜色渐变（仅首次初始化时生效，之后可在粒子材质的 color_ramp 中手动编辑） ──

@export_group("Color Ramp")
@export var color_start: Color = Color(1.0, 0.843, 0.0, 0.0)    # 透明（淡入）
@export var color_peak: Color = Color(1.0, 0.843, 0.0, 1.0)     # 金黄色 #FFD700
@export var color_mid: Color = Color(1.0, 0.89, 0.2, 1.0)       # 亮金色 #FFE333
@export var color_fade: Color = Color(1.0, 0.82, 0.1, 0.55)     # 暖金半透明
@export var color_end: Color = Color(1.0, 0.75, 0.05, 0.0)      # 暖金透明（渐隐）

# ── 纹理 ────────────────────────────────────────────────────

@export_group("Texture Generation")
@export_range(16, 256) var tex_size: int = 64
@export_range(3, 12) var tex_arms: int = 4           # 星芒数（4=十字星）
@export_range(0.0, 1.0) var tex_glow_alpha: float = 1.0

# ── 调试 ────────────────────────────────────────────────────

@export_group("Debug")
@export var auto_play_on_ready: bool = false


# ============================================================
#  生命周期
# ============================================================

func _ready() -> void:
	_apply_all_settings()
	_generate_star_texture()
	if not finished.is_connected(_on_finished):
		finished.connect(_on_finished)

	if auto_play_on_ready and not Engine.is_editor_hint():
		play(global_position)


func _apply_all_settings() -> void:
	# ── GPUParticles2D 属性 ──
	amount = burst_count
	lifetime = burst_lifetime
	one_shot = true
	explosiveness = 1.0
	speed_scale = 1.0
	local_coords = false

	# 确保粒子不被视口裁剪（在编辑器里也可见）
	visibility_rect = Rect2(-600, -600, 1200, 1200)

	# ── ParticleProcessMaterial ──
	var mat := process_material
	if not mat is ParticleProcessMaterial:
		mat = ParticleProcessMaterial.new()
		process_material = mat

	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0, 0, 1)
	mat.spread = 360.0
	mat.flatness = 1.0           # 1.0 = 完全 2D 平面展开
	mat.gravity = Vector3.ZERO

	mat.initial_velocity_min = vel_min
	mat.initial_velocity_max = vel_max
	mat.angular_velocity_min = rot_angular_min
	mat.angular_velocity_max = rot_angular_max
	mat.orbit_velocity_min = 0.0
	mat.orbit_velocity_max = 0.0
	mat.linear_accel_min = 0.0
	mat.linear_accel_max = 0.0
	mat.radial_accel_min = vel_radial_min
	mat.radial_accel_max = vel_radial_max
	mat.damping_min = vel_damping_min
	mat.damping_max = vel_damping_max
	mat.angle_min = rot_angle_min
	mat.angle_max = rot_angle_max
	mat.scale_min = scale_initial_min
	mat.scale_max = scale_initial_max

	mat.anim_speed_min = 0.0
	mat.anim_speed_max = 0.0
	mat.anim_offset_min = 0.0
	mat.anim_offset_max = 1.0
	mat.hue_variation_min = 0.0
	mat.hue_variation_max = 0.05

	# ── 颜色渐变（GradientTexture1D 包装） ──
	_setup_color_ramp(mat)

	# ── 缩放曲线 ──
	_setup_scale_curve(mat)


func _setup_color_ramp(mat: ParticleProcessMaterial) -> void:
	# color_ramp 的类型是 Texture2D（实际为 GradientTexture1D）
	var ramp_tex: GradientTexture1D
	if mat.color_ramp != null and mat.color_ramp is GradientTexture1D:
		ramp_tex = mat.color_ramp
	else:
		ramp_tex = GradientTexture1D.new()
		mat.color_ramp = ramp_tex

	# 如果已有 gradient 且用户编辑过（多个点），保留
	var g := ramp_tex.gradient
	if g == null:
		g = Gradient.new()
		ramp_tex.gradient = g
	if g.get_point_count() > 1:
		return

	# 重建默认颜色关键帧
	g.remove_point(0)
	g.add_point(0.0, color_start)
	g.add_point(0.08, color_peak)
	g.add_point(0.35, color_mid)
	g.add_point(0.65, color_fade)
	g.add_point(1.0, color_end)


func _setup_scale_curve(mat: ParticleProcessMaterial) -> void:
	# scale_curve 的类型是 Texture2D（实际为 CurveTexture）
	var curve_tex: CurveTexture
	if mat.scale_curve != null and mat.scale_curve is CurveTexture:
		curve_tex = mat.scale_curve
	else:
		curve_tex = CurveTexture.new()
		mat.scale_curve = curve_tex

	var c := curve_tex.curve
	if c == null:
		c = Curve.new()
		curve_tex.curve = c
	if c.get_point_count() > 1:
		return

	c.clear_points()
	# 从 0.8 → 1.0（闪烁峰值）→ 平缓衰减 → 0（消失）
	c.add_point(Vector2(0.0, 0.8), 0.0, 2.0)
	c.add_point(Vector2(0.12, 1.0), -1.0, 1.0)
	c.add_point(Vector2(0.45, 0.55), -0.5, -0.5)
	c.add_point(Vector2(1.0, 0.0), -2.0, 0.0)


# ============================================================
#  星形纹理生成（程序化）
# ============================================================

func _generate_star_texture() -> void:
	if texture:
		return

	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center := Vector2(tex_size / 2.0, tex_size / 2.0)
	var outer_r := tex_size / 2.0 - 1.0
	var inner_r := outer_r * 0.3

	# ── 星芒（从中心向外辐射的发光线条） ──
	var point_count := tex_arms * 2
	for i in range(point_count):
		var angle: float = i * PI / tex_arms - PI / 2.0
		var r: float = outer_r if i % 2 == 0 else inner_r
		var tip := center + Vector2(cos(angle), sin(angle)) * r
		_draw_glow_line(img, center, tip, 2.0, 1.0)

	# ── 中心强光斑 ──
	_draw_radial_glow(img, center, outer_r * 0.18, tex_glow_alpha)

	# ── 中层柔光 ──
	_draw_radial_glow(img, center, outer_r * 0.45, tex_glow_alpha * 0.2)

	# ── 外环微光（增加星芒之间的层次） ──
	var ring_r := outer_r * 0.65
	for a in range(tex_arms):
		var angle: float = a * 2.0 * PI / tex_arms - PI / 2.0
		var p := center + Vector2(cos(angle), sin(angle)) * ring_r
		_draw_radial_glow(img, p, outer_r * 0.12, tex_glow_alpha * 0.3)

	texture = ImageTexture.create_from_image(img)


func _draw_glow_line(img: Image, a: Vector2, b: Vector2, thickness: float, max_alpha: float) -> void:
	var dist: float = a.distance_to(b)
	if dist < 0.01:
		return
	var dir: Vector2 = (b - a).normalized()
	var steps: int = ceili(dist)
	var thick_i: int = ceili(thickness)
	var denom: float = maxf(1.0, dist)
	for s: int in range(steps + 1):
		var t: float = float(s) / denom
		var pos: Vector2 = a + dir * float(s)
		var alpha: float = max_alpha * (1.0 - t * 0.7)
		for tx: int in range(-thick_i, thick_i + 1):
			for ty: int in range(-thick_i, thick_i + 1):
				var edge_falloff: float = 1.0 - (abs(tx) + abs(ty)) / (thickness * 2.0 + 1.0)
				edge_falloff = clampf(edge_falloff, 0.0, 1.0)
				_blend(img, Vector2i(int(pos.x) + tx, int(pos.y) + ty),
					Color(1, 1, 1, alpha * edge_falloff * 0.7))


func _draw_radial_glow(img: Image, center: Vector2, radius: float, max_alpha: float) -> void:
	var r_i: int = ceili(radius)
	for dy: int in range(-r_i, r_i + 1):
		for dx: int in range(-r_i, r_i + 1):
			var d: float = Vector2(dx, dy).length()
			if d <= radius:
				var alpha: float = max_alpha * pow(1.0 - d / radius, 2.0)
				_blend(img,
					Vector2i(int(center.x) + dx, int(center.y) + dy),
					Color(1, 1, 1, alpha))


func _blend(img: Image, pos: Vector2i, color: Color) -> void:
	if pos.x < 0 or pos.x >= img.get_width() or pos.y < 0 or pos.y >= img.get_height():
		return
	var c := img.get_pixel(pos.x, pos.y)
	img.set_pixel(pos.x, pos.y, c.blend(color))


# ============================================================
#  公共接口
# ============================================================

## 在指定全局位置播放特效
func play(at_position: Vector2) -> void:
	global_position = at_position
	restart()
	emitting = true


## 便捷静态方法：加载场景 → 实例化 → 添加到父节点 → 播放
static func spawn(at_position: Vector2, parent: Node) -> StarBurstEffect:
	var scene := load(SCENE_PATH) as PackedScene
	if scene == null:
		push_error("[StarBurstEffect] Failed to load scene: ", SCENE_PATH)
		return null
	var fx := scene.instantiate() as StarBurstEffect
	if fx == null:
		push_error("[StarBurstEffect] Scene root is not StarBurstEffect")
		return null
	parent.add_child(fx)
	fx.play(at_position)
	return fx


# ============================================================
#  回调
# ============================================================

func _on_finished() -> void:
	# 编辑器模式下不 queue_free
	if Engine.is_editor_hint():
		return
	await get_tree().process_frame
	if is_instance_valid(self):
		queue_free()
