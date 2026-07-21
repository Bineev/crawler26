shader_type canvas_item;

uniform float debuff_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 debuff_color : source_color = vec4(0.4, 0.0, 0.5, 1.0); // Пурпурный/фиолетовый
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;

// Простая функция генерации псевдошума
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec4 card_color = texture(TEXTURE, UV);
	
	// 1. Обесцвечивание (карта теряет краски под дебаффом)
	float luma = dot(card_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(card_color.rgb, vec3(luma) * 0.6, debuff_progress);
	
	// 2. Пульсация времени для анимации скверны
	float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * debuff_progress;
	
	// 3. Продвинутая виньетка с искажением (эффект наплыва порчи)
	vec2 center_uv = UV - 0.5;
	float dist = length(center_uv);
	
	// Добавляем шум к краям, чтобы виньетка была рваной, а не идеально круглой
	float noise = hash(UV + TIME * 0.01) * 0.05;
	float vignette = smoothstep(0.4, 0.7 - (pulse * 0.1), dist + noise);
	
	// 4. Смешивание базового цвета и цвета дебаффа через рваную виньетку
	vec3 final_color = mix(desaturated, debuff_color.rgb, vignette * debuff_progress * debuff_color.a);
	
	// Вспышки по краям при сильном дебаффе
	final_color += debuff_color.rgb * vignette * pulse * 0.3;
	
	COLOR = vec4(final_color, card_color.a);
}
