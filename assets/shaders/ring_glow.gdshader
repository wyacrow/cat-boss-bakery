shader_type canvas_item;

// ============================================================
// Ring Glow Shader — 纯白单圈光环特效
// 绑定 Sprite2D 使用，无需外部贴图，纯 UV 程序化生成
// 配合 WorldEnvironment → Glow (Bloom) 实现外圈柔光光晕
// ============================================================

// 全局整体缩放（0.1=放大10倍, 2.0=缩小一半），支持代码动态插值
uniform float scale_size : hint_range(0.1, 2.0) = 1.0;

// 光环内圈基准半径（实心圆盘外缘，从此处开始出现光环）
uniform float ring_base_radius : hint_range(0.01, 0.45) = 0.15;

// 光环环带厚度
uniform float ring_thickness : hint_range(0.01, 0.25) = 0.06;

// 边缘柔和过渡系数（值越大渐变越柔和）
uniform float fade_soft : hint_range(0.005, 0.15) = 0.04;

// 自发光强度（>1.0 时可配合 Bloom 产生外扩光晕）
uniform float glow_power : hint_range(0.0, 5.0) = 2.5;

// 基础颜色（默认纯白）
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// 光环明暗脉冲速度（0=关闭闪烁，值越大闪烁越快）
uniform float pulse_speed : hint_range(0.0, 10.0) = 0.0;

void fragment() {
	// --- 将 UV 原点移至纹理中心，范围 [-0.5, +0.5] ---
	vec2 uv = UV - 0.5;

	// --- 计算到中心的径向距离，除以 scale_size 实现全局均匀缩放 ---
	// scale_size < 1.0 → 光环放大；scale_size > 1.0 → 光环缩小
	float dist = length(uv) / scale_size;

	// --- 预计算环的几何参数 ---
	float ring_inner  = ring_base_radius;                       // 环内缘
	float ring_outer  = ring_base_radius + ring_thickness;      // 环外缘
	float ring_center = (ring_inner + ring_outer) * 0.5;        // 环中心（辉光峰值位置）

	// ============================================================
	// 1. 中心实心圆盘 Alpha —— 中心完全不透明，向环内缘平滑衰减
	// ============================================================
	// dist < ring_inner - fade_soft → alpha = 1.0（完全不透明）
	// dist > ring_inner + fade_soft → alpha = 0.0（完全透明）
	float disc_alpha = 1.0 - smoothstep(
		ring_inner - fade_soft,  // smoothstep 下界：盘体开始衰减
		ring_inner + fade_soft,  // smoothstep 上界：盘体完全消失
		dist
	);

	// ============================================================
	// 2. 光环遮罩 —— 在环带区域建立从 0 → 1 → 0 的平滑曲线
	// ============================================================
	// 上升段：从 ring_inner - fade_soft 开始起峰，到 ring_center 达到 1.0
	float ring_rise = smoothstep(ring_inner - fade_soft, ring_center, dist);
	// 下降段：从 ring_center 开始衰减，到 ring_outer + fade_soft 回到 0
	float ring_fall = 1.0 - smoothstep(ring_center, ring_outer + fade_soft, dist);
	// 合成为完整光环遮罩（峰值在 ring_center 处 = 1.0）
	float ring_mask = ring_rise * ring_fall;

	// ============================================================
	// 3. 自发光辉光 —— 对光环遮罩做幂次强化，放大白色发光效果
	// ============================================================
	// pow(ring_mask, 2.0) 收窄辉光峰值，使光环更锐利聚焦
	// 结果值可超过 1.0，供 Godot Glow/Bloom 后处理捕获产生外圈光晕
	float glow = pow(ring_mask, 2.0) * glow_power;

	// ============================================================
	// 4. 最终 Alpha —— 合并圆盘与光环的透明度
	// ============================================================
	// max() 保证中心区域始终不透明，光环在半透明状态下依然可见
	float alpha = max(disc_alpha, ring_mask * 0.55);

	// ============================================================
	// 5. 最终颜色 —— 基础白色 + 辉光提亮 RGB 通道
	// ============================================================
	vec3 color = base_color.rgb + base_color.rgb * glow;

	// ============================================================
	// 6. TIME 脉冲动画 —— 正弦波明暗闪烁
	// ============================================================
	if (pulse_speed > 0.001) {
		// sin 在 [-1, 1] 振荡，映射到 [0.75, 1.25] 亮度区间
		float pulse = 1.0 + 0.25 * sin(TIME * pulse_speed);
		color *= pulse;
	}

	// ============================================================
	// 7. 最终输出
	// ============================================================
	COLOR = vec4(color, alpha * base_color.a);
}
