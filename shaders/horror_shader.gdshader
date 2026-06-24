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

// Стабильная функция шума, устойчивая к большим координатам
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Безопасное зацикливание времени для предотвращения накопления ошибок float
    float time_slow = mod(TIME, 100.0);
    float time_fast = mod(TIME, 10.0);
    
    // Получаем исходный цвет с прозрачностью
    vec4 original = texture(screen_texture, uv);
    
    // Глитч (Оптимизировано: убрали if, сделали через математический шаг step)
    float glitch_time_step = floor(time_slow * glitch_speed);
    float glitch_chance = random(vec2(glitch_time_step, 0.0));
    float is_glitch = step(0.995, glitch_chance); // Вернет 1.0 если глитч активен, иначе 0.0
    
    float offset_x = (random(vec2(floor(time_fast * 10.0), uv.y)) - 0.5) * glitch_amount * is_glitch;
    uv.x += offset_x;
    
    // Хроматическая аберрация
    float r = texture(screen_texture, uv + vec2(chromatic_amount, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(chromatic_amount, 0.0)).b;
    vec4 color = vec4(r, g, b, original.a);
    
    // Зернистость (привязываем к ограниченному по времени кадру)
    float grain_time = floor(time_fast * 10.0);
    float noise = (random(uv + vec2(grain_time, -grain_time)) - 0.5) * grain_amount;
    color.rgb += noise;
    
    // Сканлайны (синхронизируем синус с зацикленным временем)
    float scanline_wave = sin(uv.y * 800.0 + time_slow * 10.0);
    float scanline = scanline_wave * 0.1 * scanline_intensity;
    color.rgb -= scanline;
    
    // Пульсация
    float pulse_wave = sin(time_slow * pulse_speed);
    float pulse = 0.99 + pulse_wave * pulse_intensity;
    pulse += random(vec2(floor(time_fast * 2.0), 0.0)) * 0.003;
    color.rgb *= pulse;
    
    // Виньетка
    float dist = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.9, 0.7 - vignette_intensity * 0.3, dist);
    color.rgb *= vignette;
    
    // Красное свечение по краям
    float edge_glow = pow(1.0 - abs(uv.x - 0.5) * 2.0, 4.0) * pow(1.0 - abs(uv.y - 0.5) * 2.0, 4.0);
    edge_glow = clamp(edge_glow * 0.02, 0.0, 0.01);
    color.rgb += vec3(0.8, 0.1, 0.1) * edge_glow;
    
    // Вспышки (Оптимизировано: убрали if)
    float flash_chance = random(vec2(floor(time_slow * 1.5), 0.5));
    float is_flash = step(0.997, flash_chance);
    float flash = random(vec2(time_fast, 1.0)) * 0.03 * is_flash;
    color.rgb += vec3(1.0, 0.9, 0.8) * flash;
    
    // Гарантируем, что значения цветов не уйдут в минус или за пределы 1.0 из-за багов видеокарты
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    
    COLOR = color;
}
