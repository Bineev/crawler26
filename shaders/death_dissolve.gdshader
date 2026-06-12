shader_type canvas_item;

// Прогресс смерти: 0.0 - живой, 1.0 - полностью исчез
uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
// Цвет горящего края при растворении
uniform vec4 burn_color : source_color = vec4(1.0, 0.3, 0.1, 1.0); // Огненный
// Ширина горящей линии
uniform float burn_size : hint_range(0.0, 0.3) = 0.1;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec4 color = texture(TEXTURE, uv);
    
    // Создаем градиент снизу вверх, чтобы враг исчезал по направлению вверх
    // Если хотите растворение со всех сторон сразу, замените `uv.y` на `random(uv)`
    float noise = random(uv) * 0.2 + (1.0 - uv.y) * 0.8;
    
    // Порог, при котором пиксели начинают исчезать
    float threshold = death_progress * 1.2; 
    
    // Если шум меньше порога — пиксель сгорает (исчезает)
    if (noise < threshold) {
        discard;
    }
    
    // Делаем красивую светящуюся кромку на границе исчезновения
    if (noise < threshold + burn_size && death_progress > 0.0) {
        // Смешиваем текущий цвет пикселя с цветом горения
        float burn_intensity = (threshold + burn_size - noise) / burn_size;
        color.rgb = mix(color.rgb, burn_color.rgb * 2.0, burn_intensity);
    }
    
    COLOR = color;
}
