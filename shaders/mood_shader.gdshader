shader_type canvas_item;

// Параметры шейдера
uniform float darkness : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float noise_amount : hint_range(0.0, 0.1) = 0.03;
uniform vec3 tint_color : source_color = vec3(0.2, 0.05, 0.1);

// Самописная функция генерации псевдослучайного шума
float noise_gen(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // Для ColorRect берем его базовый цвет (белый) вместо чтения несуществующей TEXTURE
    vec4 color = COLOR;

    // 1. Затемнение
    color.rgb *= (1.0 - darkness);

    // 2. Виньетка (темнее по краям)
    vec2 uv = UV * 2.0 - 1.0;
    float vignette = 1.0 - length(uv) * vignette_strength;
    // Ограничиваем виньетку, чтобы она не уходила в минус (защита от багов)
    vignette = clamp(vignette, 0.0, 1.0);
    color.rgb *= vignette;

    // 3. Цветовой оттенок
    color.rgb += tint_color * 0.3;

    // 4. Безопасный шум для "зернистости"
    // Используем mod(TIME, 100.0) — это защитит от поломок при Alt-Tab и при долгой работе игры
    float safe_time = mod(TIME, 100.0);
    float grain = noise_gen(UV + safe_time) * noise_amount;
    color.rgb += grain;

    COLOR = color;
}
