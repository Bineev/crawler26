shader_type canvas_item;

// Цвет обводки/свечения
uniform vec4 line_color : source_color = vec4(0.7490, 0.6588, 0.4157, 1.0); // Золотистый по умолчанию
// Толщина линии обводки
uniform float line_thickness : hint_range(0.0, 10.0) = 3.0;
// Скорость пульсации (0.0 — статично)
uniform float pulse_speed : hint_range(0.0, 10.0) = 4.0;
// Сила свечения при наведении
uniform float hover_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    
    // Вычисляем пульсацию во времени
    float pulse = (sin(TIME * pulse_speed) * 0.25 + 0.75) * hover_intensity;
    
    // Проверяем соседние пиксели для создания обводки
    float alpha = texture(TEXTURE, UV).a;
    float outline = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
    
    // Ограничиваем значение обводки
    outline = min(outline, 1.0);
    
    // Получаем исходный цвет пикселя
    vec4 color = texture(TEXTURE, UV);
    
    // Смешиваем основной цвет с цветом обводки на краях
    vec4 final_outline_color = line_color * vec4(1.0, 1.0, 1.0, pulse);
    vec4 mixed_color = mix(color, final_outline_color, (outline - alpha));
    
    // Добавляем легкое внутреннее подсвечивание всего силуэта
    mixed_color.rgb += line_color.rgb * alpha * hover_intensity * 0.15;
    
    COLOR = mixed_color;
}
