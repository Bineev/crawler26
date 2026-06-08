shader_type canvas_item;

uniform float breath_speed : hint_range(0.0, 2.0) = 0.8;
uniform float breath_amount : hint_range(0.0, 0.05) = 0.015;
uniform float wobble_speed : hint_range(0.0, 3.0) = 1.2;
uniform float wobble_amount : hint_range(0.0, 0.02) = 0.006;
uniform float jitter_strength : hint_range(0.0, 0.02) = 0.003;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float time = TIME;

    // 1. Дыхание (лёгкое масштабирование от центра)
    float breath = 1.0 + sin(time * breath_speed) * breath_amount;
    vec2 centered = uv - 0.5;
    centered *= breath;
    uv = centered + 0.5;

    // 2. Покачивание (едва заметная волна)
    float wobble = sin(uv.y * 15.0 + time * wobble_speed) * wobble_amount;
    uv.x += wobble;

    // 3. Микродрожь (случайная)
    float jitter_x = (random(vec2(floor(time * 20.0), uv.y)) - 0.5) * jitter_strength;
    float jitter_y = (random(vec2(floor(time * 20.0), uv.x)) - 0.5) * jitter_strength;
    uv.x += jitter_x;
    uv.y += jitter_y;

    vec4 color = texture(TEXTURE, uv);

    // Сохраняем прозрачность
    color.a = texture(TEXTURE, UV).a;

    // Лёгкое изменение яркости при дыхании
    color.rgb *= (0.95 + sin(time * breath_speed) * 0.03);

    COLOR = color;
}