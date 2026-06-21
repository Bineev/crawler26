shader_type canvas_item;

uniform float contrast : hint_range(0.0, 3.0) = 1.5;
uniform float grayscale_intensity : hint_range(0.0, 1.0) = 0.8;
uniform vec3 tint_color : source_color = vec3(1.0, 0.85, 0.3);
uniform float tint_intensity : hint_range(0.0, 1.0) = 0.15;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Черно-белый
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gray_color = vec3(gray);
    vec3 mixed = mix(tex_color.rgb, gray_color, grayscale_intensity);
    
    // Контраст
    mixed = (mixed - 0.5) * contrast + 0.5;
    
    // Тонировка
    mixed = mix(mixed, mixed * tint_color, tint_intensity);
    
    mixed = clamp(mixed, 0.0, 1.0);
    
    COLOR = vec4(mixed, tex_color.a);
}