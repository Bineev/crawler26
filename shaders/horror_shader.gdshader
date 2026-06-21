shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Настройки эффектов (минимальные, почти незаметные)
uniform float grain_amount : hint_range(0.0, 0.05) = 0.003;
uniform float scanline_intensity : hint_range(0.0, 0.5) = 0.01;
uniform float vignette_intensity : hint_range(0.0, 0.5) = 0.08;
uniform float glitch_amount : hint_range(0.0, 0.05) = 0.001;
uniform float glitch_speed : hint_range(0.0, 10.0) = 1.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.6;
uniform float pulse_intensity : hint_range(0.0, 0.2) = 0.01;
uniform float chromatic_amount : hint_range(0.0, 0.005) = 0.0001;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

bool is_glitch_active(float time) {
    float glitch_chance = random(vec2(floor(time * glitch_speed), 0.0));
    return glitch_chance > 0.995;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float time = TIME;
    
    // Получаем исходный цвет с прозрачностью
    vec4 original = texture(screen_texture, uv);
    
    // Глитч (очень редко)
    if (is_glitch_active(time)) {
        float offset_x = (random(vec2(floor(time * 10.0), uv.y)) - 0.5) * glitch_amount;
        uv.x += offset_x;
    }
    
    // Хроматическая аберрация (почти нет)
    float r = texture(screen_texture, uv + vec2(chromatic_amount, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(chromatic_amount, 0.0)).b;
    vec4 color = vec4(r, g, b, original.a);
    
    // Зернистость
    float noise = (random(uv + floor(time * 10.0)) - 0.5) * grain_amount;
    color.rgb += noise;
    
    // Сканлайны
    float scanline = sin(uv.y * 800.0 + time * 10.0) * 0.1 * scanline_intensity;
    color.rgb -= scanline;
    
    // Пульсация
    float pulse = 0.99 + sin(time * pulse_speed) * pulse_intensity;
    pulse += random(vec2(floor(time * 2.0), 0.0)) * 0.003;
    color.rgb *= pulse;
    
    // Виньетка (очень лёгкая)
    float dist = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.9, 0.7 - vignette_intensity * 0.3, dist);
    color.rgb *= vignette;
    
    // Красное свечение по краям (почти нет)
    float edge_glow = pow(1.0 - abs(uv.x - 0.5) * 2.0, 4.0) * pow(1.0 - abs(uv.y - 0.5) * 2.0, 4.0);
    edge_glow = clamp(edge_glow * 0.02, 0.0, 0.01);
    color.rgb += vec3(0.8, 0.1, 0.1) * edge_glow;
    
    // Вспышки
    float flash = 0.0;
    float flash_chance = random(vec2(floor(time * 1.5), 0.5));
    if (flash_chance > 0.997) {
        flash = random(vec2(time, 1.0)) * 0.03;
        color.rgb += vec3(1.0, 0.9, 0.8) * flash;
    }
    
    COLOR = color;
}