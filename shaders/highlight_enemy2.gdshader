shader_type canvas_item;

// --- НАСТРОЙКИ БЛИКА (ЭФФЕКТ РЕДКОСТИ) ---
uniform float shine_speed : hint_range(0.0, 5.0) = 1.5;
uniform float shine_width : hint_range(0.0, 1.0) = 0.2;
uniform float shine_intensity : hint_range(0.0, 1.0) = 0.4;
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pulse_alpha : hint_range(0.0, 1.0) = 0.3;  // ← добавить
// --- НАСТРОЙКИ ПУЛЬСАЦИИ (ДЛЯ РЕЖИМА AIMING) ---
uniform float hover_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;
uniform vec4 pulse_color : source_color = vec4(1.0, 0.85, 0.3, 1.0);

void fragment() {
    // 1. Получаем исходный цвет карты
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 2. Расчет бегущей диагональной линии
    float shine_line = UV.x + UV.y;
    float shine_cycle = mod(TIME * shine_speed, 3.0) - 1.0;
    float shine_factor = smoothstep(shine_width, 0.0, abs(shine_line - shine_cycle));
    vec4 final_shine = shine_color * shine_factor * shine_intensity;
    
    // 3. Пульсация (для режима AIMING)
    float pulse = (sin(TIME * pulse_speed) * 0.3 + 0.7) * hover_intensity;
    vec4 final_pulse = pulse_color * pulse * pulse_alpha;  // ← умножить на прозрачность
    
    // 4. Накладываем эффекты поверх карты
    vec4 result = tex_color + (final_shine * tex_color.a) + (final_pulse * tex_color.a * 0.5);
    
    // Сохраняем исходную прозрачность
    result.a = tex_color.a;
    
    COLOR = result;
}