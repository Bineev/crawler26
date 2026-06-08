# shaders/mood_shader.gdshader
shader_type canvas_item;

// Параметры шейдера
uniform float darkness : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform float noise_amount : hint_range(0.0, 0.1) = 0.03;
uniform vec3 tint_color : source_color = vec3(0.2, 0.05, 0.1);

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Затемнение
    color.rgb *= (1.0 - darkness);

    // Виньетка (темнее по краям)
    vec2 uv = UV * 2.0 - 1.0;
    float vignette = 1.0 - length(uv) * vignette_strength;
    color.rgb *= vignette;

    // Цветовой оттенок
    color.rgb += tint_color * 0.3;

    // Лёгкий шум для "зернистости"
    float grain = rand(UV + TIME) * noise_amount;
    color.rgb += grain;

    COLOR = color;
}