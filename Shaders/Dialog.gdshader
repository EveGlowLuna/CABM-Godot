shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);

uniform float bottom_alpha : hint_range(0.0, 1.0) = 0.7;

void fragment() {
    float y = UV.y;
    float from_bottom = 1.0 - y;

    float alpha = mix(bottom_alpha, 0.0, from_bottom);

    COLOR = vec4(base_color.rgb, alpha);
}