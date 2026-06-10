shader_type canvas_item;

// Настройки атмосферы подземелья
uniform vec4 vignette_color : source_color = vec4(0.02, 0.01, 0.01, 1.0); // Почти черный цвет тьмы
uniform float darkness_power : hint_range(0.0, 3.0) = 1.6;               // Сила тьмы по краям карты
uniform float light_radius : hint_range(0.0, 1.0) = 0.45;                // Радиус света от факела в центре
uniform float flicker_speed : hint_range(0.0, 20.0) = 8.0;               // Скорость дрожания факела

// Функция генерации шума для эффекта старой пошарпанной бумаги/грязи
float pseudo_noise(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// 1. Расстояние от центра карты (0.0 в центре, 0.5+ по углам)
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	
	// 2. Эффект дрожания факела (flicker) через синусоиды времени
	float flicker = sin(TIME * flicker_speed) * 0.03 + cos(TIME * flicker_speed * 0.7) * 0.02;
	float dynamic_radius = light_radius + flicker;
	
	// 3. Создаем глубокую виньетку (тьма, поглощающая карту)
	float vignette = smoothstep(dynamic_radius, dynamic_radius + 0.3, dist);
	// Делаем затенение более агрессивным к углам
	vignette = pow(vignette, darkness_power);
	
	// 4. Добавляем атмосферную грязь и шум (пыль подземелья)
	float noise = pseudo_noise(UV * 100.0 + floor(TIME * 12.0)) * 0.04;
	
	// Суммируем маску темноты и добавляем к ней шум в темных зонах
	float final_darkness = clamp(vignette + (noise * vignette), 0.0, 1.0);
	
	// 5. КОМПОНОВКА
	// Шейдер выдает цвет виньетки (мрака) и регулирует его прозрачность по краям.
	// Центр карты остается на 100% прозрачным (видны ваши оригинальные карты),
	// а края плавно и «живо» затягиваются факельной тьмой.
	COLOR = vec4(vignette_color.rgb, final_darkness * vignette_color.a);
}
