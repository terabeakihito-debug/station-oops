shader_type canvas_item;

uniform float pixel_step : hint_range(1.0, 6.0, 1.0) = 1.0;
uniform float palette_steps : hint_range(4.0, 24.0, 1.0) = 10.0;

void fragment() {
	vec4 vertex_color = COLOR;
	vec2 texel = TEXTURE_PIXEL_SIZE * pixel_step;
	vec2 sample_uv = floor(UV / texel) * texel + texel * 0.5;
	vec4 sprite = texture(TEXTURE, sample_uv);
	if (sprite.a < 0.02) {
		COLOR = vec4(0.0);
	} else {
		sprite.rgb = floor(sprite.rgb * palette_steps + 0.5) / palette_steps;
		COLOR = sprite * vertex_color;
	}
}
