shader_type canvas_item;

uniform float amplitude = 1;
uniform float speed = 5.0;
uniform float tiling = 10.0;

uniform vec3 color: source_color;
uniform float flash_intensity: hint_range(0.0, 1.0);

void fragment() {
    // Calculate a wobble offset using a noise function
    vec2 wobble = vec2(
		sin(TIME * speed + UV.y * tiling),
		cos(TIME * speed + UV.x * tiling)
	) * (amplitude/100.0);

    // Create a new UV coordinate with the wobble
    vec2 newUV = UV + wobble;

    // Output the texture with the modified UVs
    COLOR = texture(TEXTURE, newUV);
	
	vec4 pixelColor = texture(TEXTURE, newUV);
	COLOR.rgb = mix(pixelColor.rgb, color, flash_intensity);
}