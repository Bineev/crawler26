shader_type canvas_item;

// Режим unshaded отключает влияние стандартного освещения Godot на оверлей
render_mode unshaded;

// --- ПАРАМЕТРЫ ДЛЯ АНИМАЦИИ ИЗ КОДА (Инспектор / Tween) ---
uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform float burn_size : hint_range(0.0, 0.3) = 0.08;
// Цвет, в который превращается сгоревшая область карты (пепел/пустота)
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// --- НАСТРОЙКИ ВНЕШНЕГО ВИДА ШУМА ---
const float NOISE_SCALE = 8.0;      // РАЗМЕР КЛОЧЬЕВ: меньше = крупнее, больше = мельче
const float NOISE_INFLUENCE = 0.4; // ВЛИЯНИЕ ШУМА: 0.1 = ровная линия, 0.9 = рваные дыры
const float GLOW_POWER = 2.5;       // ЯРКОСТЬ СВЕЧЕНИЯ: сила горения края

// Текстура экрана для захвата всех UI элементов под ColorRect
uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;

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

// Фрактальный шум для детализации краев горения
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
    // Считываем пиксели карты из текстуры экрана с помощью SCREEN_UV
    vec4 canvas_color = texture(screen_texture, SCREEN_UV);
    
    // Генерируем текстуру шума по всему экрану
    float smooth_noise = fbm(SCREEN_UV * NOISE_SCALE);
    
    // Формируем волну растворения, идущую снизу вверх
    float noise = smooth_noise * NOISE_INFLUENCE + (1.0 - SCREEN_UV.y) * (1.0 - NOISE_INFLUENCE);
    
    // Корректируем порог под анимацию от 0.0 до 1.0
    float threshold = death_progress; 
    
    // Переменная для финального цвета пикселя
    vec3 final_rgb = canvas_color.rgb;
    
    if (noise < threshold) {
        // ЗОНА СГОРЕЛА: заменяем карту на цвет заднего фона
        final_rgb = background_color.rgb;
    } 
    else if (noise < threshold + burn_size && death_progress > 0.0) {
        // ЗОНА ГОРЕНИЯ (КРАЙ): плавно смешиваем исходную карту с цветом пламени
        float burn_intensity = (threshold + burn_size - noise) / burn_size;
        
        // Делаем переход более контрастным и выразительным
        burn_intensity = pow(burn_intensity, 2.0); 
        
        // Смешиваем оригинальный цвет с цветом горения, умноженным на силу свечения
        final_rgb = mix(canvas_color.rgb, burn_color.rgb * GLOW_POWER, burn_intensity);
    }
    
    // Выводим результат. Альфа всегда 1.0, чтобы полностью перекрывать оригинальный интерфейс под нами
    COLOR = vec4(final_rgb, 1.0);
}
