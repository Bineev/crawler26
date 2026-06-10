shader_type canvas_item;

// Параметры рамки выделения
uniform vec4 glow_color : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform float glow_thickness : hint_range(0.0, 0.2) = 0.04; // Толщина рамки вовнутрь
uniform float glow_softness : hint_range(0.0, 0.2) = 0.01;  // Мягкость/размытие рамки

// Параметры блика
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float flash_speed : hint_range(0.0, 5.0) = 2.0;     // Скорость движения
uniform float flash_width : hint_range(0.0, 0.5) = 0.15;    // Ширина полосы блика

void fragment() {
	// 1. Считаем расстояние от краев ColorRect вовнутрь (от 0.0 на самом краю до 0.5 в центре)
	vec2 border_dist = min(UV, 1.0 - UV);
	float current_dist = min(border_dist.x, border_dist.y);
	
	// 2. Создаем маску для рамки выделения у краев
	float border_mask = smoothstep(glow_thickness + glow_softness, glow_thickness, current_dist);
	float edge_glow = smoothstep(glow_softness, 0.0, current_dist);
	float final_border_mask = max(border_mask, edge_glow);
	
	// 3. Расчет бегущего блика (он будет виден на всей площади)
	float progress = mod(TIME * flash_speed, 3.0) - 1.0;
	float flash_line = UV.x + UV.y;
	float flash_glow = smoothstep(progress - flash_width, progress, flash_line) - 
					   smoothstep(progress, progress + flash_width, flash_line);
	
	// Маска блика (плавно исчезает к центру, чтобы не быть просто жесткой полосой)
	float flash_mask = flash_glow * flash_color.a;

	// 4. КОМПОНОВКА ПРОЗРАЧНОСТИ
	// Мы смешиваем цвет рамки и цвет блика. 
	// Главное: альфа-канал (прозрачность) складывается из маски рамки и маски блика.
	vec3 final_rgb = mix(flash_color.rgb, glow_color.rgb, final_border_mask);
	float final_alpha = max(final_border_mask * glow_color.a, flash_mask);
	
	COLOR = vec4(final_rgb, final_alpha);
}
