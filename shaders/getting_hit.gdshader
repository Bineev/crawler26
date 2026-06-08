shader_type canvas_item;

uniform float glitch_chance : hint_range(0.0, 0.2) = 0.06;
uniform float glitch_strength : hint_range(0.0, 0.1) = 0.02;
uniform float stretch_chance : hint_range(0.0, 0.2) = 0.04;
uniform float stretch_strength : hint_range(0.0, 0.1) = 0.03;
uniform float warp_chance : hint_range(0.0, 0.2) = 0.05;
uniform float warp_strength : hint_range(0.0, 0.05) = 0.015;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME;

    // Случайные триггеры для разных эффектов
    float glitch_trigger = step(1.0 - glitch_chance, random(vec2(floor(time * 3.0), 0.0)));
    float stretch_trigger = step(1.0 - stretch_chance, random(vec2(floor(time * 4.0), 1.0)));
    float warp_trigger = step(1.0 - warp_chance, random(vec2(floor(time * 2.5), 2.0)));

    // 1. Глитч (сдвиг по X)
    if (glitch_trigger > 0.5) {
        float offset = (random(vec2(floor(time * 10.0), uv.y)) - 0.5) * glitch_strength;
        uv.x += offset;
    }

    // 2. Растягивание (волна)
    if (stretch_trigger > 0.5) {
        float stretch = sin(uv.y * 30.0 - time * 15.0) * stretch_strength;
        uv.x += stretch;
    }

    // 3. Искажение (дрожь по вертикали)
    if (warp_trigger > 0.5) {
        float warp = sin(uv.y * 40.0 + time * 20.0) * warp_strength;
        uv.x += warp;
        uv.y += warp * 0.5;
    }

    vec4 color = texture(TEXTURE, uv);

    // Сохраняем оригинальную прозрачность
    color.a = texture(TEXTURE, UV).a;

    // Лёгкое красное свечение при глитче
    if (glitch_trigger > 0.5) {
        color.rgb += vec3(0.15, 0.02, 0.05);
    }

    COLOR = color;
}