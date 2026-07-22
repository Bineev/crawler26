shader_type canvas_item;

uniform float debuff_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 debuff_color : source_color = vec4(0.4, 0.0, 0.5, 1.0);
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;

// Параметры для настройки искажения
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.03;
uniform float wave_frequency : hint_range(1.0, 30.0) = 15.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	// 1. Вычисляем пульсацию времени
	float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * debuff_progress;
	
	// 2. ИСКАЖЕНИЕ И СЖАТИЕ UV
	vec2 center_uv = UV - 0.5;
	float dist = length(center_uv);
	
	// Создаем волновое смещение, которое усиливается к краям карты
	float wave = sin(dist * wave_frequency - TIME * pulse_speed) * distortion_strength * debuff_progress;
	
	// Смещаем UV к центру (эффект сжатия) и добавляем волну
	vec2 distorted_uv = UV + normalize(center_uv) * wave * dist;
	
	// Читаем текстуру по искаженным координатам
	vec4 card_color = texture(TEXTURE, distorted_uv);
	
	// 3. Обесцвечивание
	float luma = dot(card_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(card_color.rgb, vec3(luma) * 0.6, debuff_progress);
	
	// 4. Продвинутая виньетка
	float noise_vignette = hash(UV + TIME * 0.01) * 0.05;
	float vignette = smoothstep(0.4, 0.7 - (pulse * 0.1), dist + noise_vignette);
	
	// 5. Смешивание финального цвета
	vec3 final_color = mix(desaturated, debuff_color.rgb, vignette * debuff_progress * debuff_color.a);
	
	// Вспышки по краям
	final_color += debuff_color.rgb * vignette * pulse * 0.3;
	
	COLOR = vec4(final_color, card_color.a);
}
