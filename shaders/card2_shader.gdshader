shader_type canvas_item;

// Настройки внешнего вида
uniform vec4 dirt_color : source_color = vec4(0.18, 0.12, 0.08, 0.6); 
uniform float grain_intensity : hint_range(0.0, 0.3) = 0.08;         
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.45;             
uniform float scratch_amount : hint_range(0.0, 1.0) = 0.25;          

// Настройки мрачной виньетки (тьмы по краям)
uniform vec4 vignette_color : source_color = vec4(0.01, 0.01, 0.01, 1.0);
uniform float darkness_power : hint_range(0.0, 3.0) = 1.8;

// СКРУГЛЕНИЕ УГЛОВ (0.0 — острые, 0.5 — круг)
uniform float card_roundness : hint_range(0.0, 0.5) = 0.05;

// Сюда скрипт передает наклон карты
uniform vec2 mouse_offset = vec2(0.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 3; i++) {
		value += amplitude * noise(p);
		p *= 2.5;
		amplitude *= 0.5;
	}
	return value;
}

// Математическая функция для расчета скругленного прямоугольника
float sd_rounded_box(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

void fragment() {
	// --- 1. РАСЧЕТ СКРУГЛЕНИЯ УГЛОВ ---
	vec2 centered_uv = UV - vec2(0.5);
	// Рассчитываем маску: 1.0 внутри карты, 0.0 на скругленных углах наружу
	float corner_dist = sd_rounded_box(centered_uv, vec2(0.5), card_roundness);
	float corners_mask = smoothstep(0.005, 0.0, corner_dist);

	// --- 2. ГЕНЕРАЦИЯ ЭФФЕКТОВ (ПАРАЛЛАКС) ---
	vec2 parallax_uv = UV + (mouse_offset * 0.01);
	
	float grain = hash(parallax_uv * 999.0) * grain_intensity;
	float dirt = fbm(parallax_uv * 4.5) * dirt_amount;
	
	float lines = noise(vec2(parallax_uv.x * 40.0, parallax_uv.y * 2.0)) * noise(vec2(parallax_uv.x * 2.0, parallax_uv.y * 40.0));
	float scratches = smoothstep(0.18, 0.22, lines) * scratch_amount;
	
	float total_damage = clamp(grain + dirt + scratches, 0.0, 1.0);
	
	// --- 3. ВИНЬЕТКА ПО КРАЯМ ---
	float dist = length(centered_uv);
	float vignette = smoothstep(0.35, 0.75, dist);
	vignette = pow(vignette, darkness_power);
	
	// --- 4. КОМПОНОВКА ---
	vec3 final_rgb = mix(dirt_color.rgb, vignette_color.rgb, vignette);
	float final_alpha = max(total_damage * dirt_color.a, vignette * vignette_color.a);
	
	// Умножаем финальную прозрачность на маску углов, чтобы обрезать их
	COLOR = vec4(final_rgb, final_alpha * corners_mask);
}
