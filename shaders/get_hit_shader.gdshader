shader_type canvas_item;

// Этот параметр мы анимируем от 1.0 (удар) до 0.0 (покой)
uniform float hit_progress : hint_range(0.0, 1.0) = 0.0;

uniform float glitch_chance : hint_range(0.0, 0.5) = 0.3;
uniform float glitch_strength : hint_range(0.0, 0.2) = 0.05;
uniform float stretch_chance : hint_range(0.0, 0.5) = 0.2;
uniform float stretch_strength : hint_range(0.0, 0.2) = 0.04;
uniform float warp_chance : hint_range(0.0, 0.5) = 0.3;
uniform float warp_strength : hint_range(0.0, 0.1) = 0.02;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    
    // Вместо бесконечного TIME используем прогресс удара
    float t = hit_progress; 

    // Триггеры срабатывают, только если hit_progress > 0
    float glitch_trigger = step(1.0 - (glitch_chance * step(0.01, t)), random(vec2(floor(t * 15.0), 0.0)));
    float stretch_trigger = step(1.0 - (stretch_chance * step(0.01, t)), random(vec2(floor(t * 20.0), 1.0)));
    float warp_trigger = step(1.0 - (warp_chance * step(0.01, t)), random(vec2(floor(t * 12.0), 2.0)));

    // 1. Глитч (сдвиг по X)
    if (glitch_trigger > 0.5) {
        float offset = (random(vec2(floor(t * 30.0), uv.y)) - 0.5) * glitch_strength * t;
        uv.x += offset;
    }

    // 2. Растягивание (волна)
    if (stretch_trigger > 0.5) {
        float stretch = sin(uv.y * 40.0 - t * 50.0) * stretch_strength * t;
        uv.x += stretch;
    }

    // 3. Искажение (дрожь по вертикали)
    if (warp_trigger > 0.5) {
        float warp = sin(uv.y * 50.0 + t * 40.0) * warp_strength * t;
        uv.x += warp;
        uv.y += warp * 0.5;
    }

    // Берем цвет и прозрачность из ИСКАЖЕННЫХ координат uv
    vec4 color = texture(TEXTURE, uv);

    // Добавляем красную вспышку, сила которой завязана на hit_progress
    color.rgb = mix(color.rgb, vec3(1.0, 0.1, 0.2), hit_progress * 0.6);

    // Дополнительное свечение при глитче
    if (glitch_trigger > 0.5) {
        color.rgb += vec3(0.2, 0.0, 0.05) * t;
    }

    COLOR = color;
}
