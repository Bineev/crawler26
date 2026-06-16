shader_type canvas_item;

// Параметры для управления из кода игры (через set_shader_parameter)
uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform float burn_size : hint_range(0.0, 0.3) = 0.08;

// --- НАСТРОЙКИ ВНЕШНЕГО ВИДА (Крутить здесь) ---
const float NOISE_SCALE = 8.0;      // РАЗМЕР КЛОЧЬЕВ: меньше = крупнее, больше = мельче
const float NOISE_INFLUENCE = 0.4; // ВЛИЯНИЕ ШУМА: 0.1 = ровная линия, 0.9 = рваные дыры
const float GLOW_POWER = 2.5;       // ЯРКОСТЬ СВЕЧЕНИЯ: сила горения края
// -----------------------------------------------

// Функция генерации плавного градиентного шума (Value Noise)
float noise_value(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float a = fract(sin(dot(i + vec2(0.0,0.0), vec2(127.1,311.7))) * 43758.5453123);
    float b = fract(sin(dot(i + vec2(1.0,0.0), vec2(127.1,311.7))) * 43758.5453123);
    float c = fract(sin(dot(i + vec2(0.0,1.0), vec2(127.1,311.7))) * 43758.5453123);
    float d = fract(sin(dot(i + vec2(1.0,1.0), vec2(127.1,311.7))) * 43758.5453123);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// Фрактальный шум для улучшения детализации краев
float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise_value(uv);
        uv *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV;
    vec4 color = texture(TEXTURE, uv);
    
    // Генерируем красивый плавный шум
    float smooth_noise = fbm(uv * NOISE_SCALE);
    
    // Формируем волну растворения снизу вверх
    float noise = smooth_noise * NOISE_INFLUENCE + (1.0 - uv.y) * (1.0 - NOISE_INFLUENCE);
    
    // Корректируем порог, чтобы враг гарантированно исчезал полностью
    float threshold = death_progress * 2.0; 
    
    if (noise < threshold) {
        discard;
    }
    
    if (noise < threshold + burn_size && death_progress > 0.0) {
        float burn_intensity = (threshold + burn_size - noise) / burn_size;
        // Заостряем переход горения, чтобы край был четче
        burn_intensity = pow(burn_intensity, 2.0); 
        
        color.rgb = mix(color.rgb, burn_color.rgb * GLOW_POWER, burn_intensity);
    }
    
    COLOR = color;
}
