shader_type canvas_item;

// Вместо hint_screen_texture используем встроенную текстуру самого вьюпорта
// В Godot 4 она автоматически доступна через встроенное слово TEXTURE

uniform sampler2D slash_mask : hint_default_black, filter_linear;
uniform sampler2D noise_tex : hint_normal, filter_linear;

uniform vec4 cut_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.03;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

const float slash_width = 0.3;

void fragment() {
	// Мягкий предохранитель: если прогресс на границах, эффект равен 0
	float effect_active = smoothstep(0.0, 0.01, progress) * smoothstep(1.0, 0.99, progress);

	// НАПРАВЛЕНИЕ: Из правого верхнего угла в левый нижний
	float direction_mask = dot(vec2(1.0 - UV.x, UV.y), normalize(vec2(1.0, 1.0)));
	direction_mask = (direction_mask + 1.0) * 0.5;

	float current_progress = progress * (1.0 + slash_width);
	float leading_edge = smoothstep(current_progress - slash_width, current_progress, direction_mask);
	float trailing_edge = smoothstep(current_progress, current_progress + slash_width, direction_mask);
	float wipe = leading_edge - trailing_edge;
	
	float mask = texture(slash_mask, UV).r;
	float alpha = mask * wipe * effect_active;
	
	// Берем шум и искажаем обычные UV-координаты текстуры вьюпорта (НЕ SCREEN_UV!)
	vec2 noise = texture(noise_tex, UV).rg * 2.0 - 1.0;
	vec2 distorted_uv = UV + noise * distortion_strength * alpha;
	
	// Считываем пиксель из встроенной текстуры TEXTURE
	vec4 screen_color = texture(TEXTURE, distorted_uv);
	
	vec3 final_color = mix(screen_color.rgb, cut_color.rgb, alpha * cut_color.a);
	
	COLOR = vec4(final_color, screen_color.a);
}
