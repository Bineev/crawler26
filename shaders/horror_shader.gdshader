shader_type canvas_item;

uniform float noise_amount : hint_range(0.0, 0.1) = 0.05;
uniform float flicker_speed : hint_range(0.0, 5.0) = 2.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    // Шум
    float grain = random(UV + floor(TIME * 10.0)) * noise_amount;
    color.rgb += grain;
    
    // Мерцание
    float flicker = 0.9 + sin(TIME * flicker_speed) * 0.1;
    color.rgb *= flicker;
    
    COLOR = color;
}