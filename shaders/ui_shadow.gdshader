shader_type canvas_item;

// Настройки проекции тени на пол (можно крутить в инспекторе)
uniform float shadow_height : hint_range(0.0, 1.0) = 0.35; // Сплюснутость (чем меньше, тем площе тень)
uniform float shadow_width : hint_range(0.5, 3.0) = 1.3;   // Ширина тени под лапами
uniform float shadow_skew : hint_range(-1.0, 1.0) = -0.15; // Наклон вбок (уход вглубь пещеры)
uniform float vertical_offset : hint_range(-0.5, 0.5) = 0.05; // Коррекция "под лапы" (выше/ниже)
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.6); // Цвет и прозрачность

void fragment() {
    vec2 uv = UV;
    
    // 1. Сдвигаем точку начала координат в нижний центр кадра (в ноги врагу)
    uv.x -= 0.5;
    uv.y -= 1.0 - vertical_offset;
    
    // 2. Магия трансформации: сплющиваем по вертикали и расширяем по горизонтали
    uv.y /= shadow_height;
    uv.x /= shadow_width;
    
    // 3. Наклоняем тень по оси X в зависимости от высоты (чтобы она уходила по диагонали)
    uv.x -= uv.y * shadow_skew;
    
    // 4. Возвращаем координаты UV в стандартный диапазон Godot (0.0 - 1.0)
    uv.x += 0.5;
    uv.y += 1.0;
    
    // 5. Проверяем, не вышли ли мы за границы текстуры после деформации
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0); // За границами рисуем пустоту
    } else {
        // Берем форму врага из измененных координат
        vec4 sprite_alpha = texture(TEXTURE, uv);
        // Красим её в чистый цвет тени, используя оригинальную прозрачность
        COLOR = vec4(shadow_color.rgb, sprite_alpha.a * shadow_color.a);
    }
}
