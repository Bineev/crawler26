shader_type canvas_item;

// Текстура трещин (загрузите ч/б текстуру шума или льда в инспекторе)
uniform sampler2D ice_cracks_tex : filter_linear, repeat_enable;

// Настройки цвета и параметров
uniform vec4 ice_color : source_color = vec4(0.3, 0.65, 0.95, 1.0);
uniform vec4 glow_color : source_color = vec4(0.6, 0.85, 1.0, 1.0);
uniform float freeze_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    // 1. Эффект нарастания льда снизу вверх
    // Чем выше freeze_amount, тем выше поднимается лед по спрайту
    float ice_mask = step(1.0 - UV.y, freeze_amount);
    
    // 2. Добавляем ледяные трещины
    // Смещаем текстуру трещин по времени для эффекта «живого» льда
    vec2 moving_uv = UV * 1.5 + vec2(TIME * 0.02, TIME * 0.01);
    float cracks = texture(ice_cracks_tex, moving_uv).r;
    
    // Тонкая настройка видимости трещин
    cracks = smoothstep(0.4, 0.8, cracks) * ice_mask;
    
    // 3. Пульсация свечения льда
    float pulse = (sin(TIME * 3.0) + 1.0) * 0.5;
    vec4 current_glow = mix(ice_color, glow_color, pulse * 0.4);
    
    // 4. Финальное смешивание
    // Делаем базовую текстуру синеватой там, где есть лед
    float brightness = (base_color.r + base_color.g + base_color.b) / 3.0;
    vec4 frozen_base = vec4(brightness) * current_glow;
    
    // Накладываем трещины поверх замороженной базы
    vec4 final_ice = mix(frozen_base, glow_color, cracks);
    final_ice.a = base_color.a; // Сохраняем прозрачность спрайта
    
    // Смешиваем обычного врага с замороженным по маске нарастания
    COLOR = mix(base_color, final_ice, ice_mask);
}
