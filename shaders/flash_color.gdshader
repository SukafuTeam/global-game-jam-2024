shader_type canvas_item;

uniform vec3 color: source_color;
uniform float flash_intensity: hint_range(0.0, 1.0);

void fragment() {
	vec4 pixelColor = texture(TEXTURE, UV);
	COLOR.rgb = mix(pixelColor.rgb, color, flash_intensity);
}
