shader_type canvas_item;

// Текстура шума (грязь, царапины, волокна бумаги)
uniform sampler2D grunge_noise_tex : repeat_enable, filter_linear_mipmap;

// Настройки эффекта
uniform float grunge_intensity : hint_range(0.0, 1.0) = 0.35; // Сила проявления грязи
uniform float jitter_speed : hint_range(0.0, 30.0) = 8.0;     // Скорость дерганья
uniform float jitter_amount : hint_range(0.0, 0.05) = 0.003;  // Амплитуда смещения
uniform vec4 paper_tint : source_color = vec4(0.9, 0.85, 0.8, 1.0); // Тон пожелтения

// Генератор псевдослучайных чисел для пошагового времени
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void fragment() {
    // 1. Создаем "пошаговое" время, чтобы дерганье было не плавным, а как в покадровой анимации (стоп-моушен)
    float stepped_time = floor(TIME * jitter_speed);
    
    // Генерируем случайное смещение для этого кадра
    vec2 jitter = vec2(
        hash(stepped_time + 1.0),
        hash(stepped_time + 2.0)
    ) * 2.0 - 1.0;
    
    // Смещаем UV-координаты для эффекта дрожания краев
    vec2 jittered_uv = UV + jitter * jitter_amount;
    
    // Исходный цвет портрета со смещенных координат
    vec4 base_color = texture(TEXTURE, jittered_uv);
    
    // 2. Рассчитываем UV для текстуры грязи (смещаем ее сильнее, чтобы пятна менялись)
    vec2 noise_uv = UV + jitter * 0.15;
    vec4 noise_color = texture(grunge_noise_tex, noise_uv);
    
    // Имитируем старую бумагу: накладываем текстуру шума через режим Multiply (умножение)
    // Черные пятна и царапины въедаются в арт, а белые зоны остаются нетронутыми
    vec3 grunge_effect = base_color.rgb * noise_color.rgb;
    
    // Немного тонируем портрет под старую пожелтевшую бумагу в светлых участках
    grunge_effect *= paper_tint.rgb;
    
    // Смешиваем исходный арт с потасканным вариантом на основе ползунка интенсивности
    vec3 final_rgb = mix(base_color.rgb, grunge_effect, grunge_intensity);
    
    // Выводим результат, сохраняя альфа-канал (прозрачность) портрета
    COLOR = vec4(final_rgb, base_color.a);
}
