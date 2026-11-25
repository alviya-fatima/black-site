shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.038;
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.62;
uniform float desaturation : hint_range(0.0, 1.0) = 0.14;
uniform float scanline_strength : hint_range(0.0, 0.15) = 0.018;
uniform float warm_stain : hint_range(0.0, 1.0) = 0.035;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_texture, uv).rgb;
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(luma), desaturation);
	col = mix(col, col * vec3(1.035, 1.0, 0.94), warm_stain);

	float grain = hash12(uv * vec2(1280.0, 720.0) + vec2(TIME * 37.0, TIME * 19.0)) - 0.5;
	col += grain * grain_amount;

	float dist = length((uv - vec2(0.5, 0.5)) * vec2(1.03, 1.18));
	float vig = smoothstep(0.32, 0.84, dist);
	col *= 1.0 - vig * vignette_strength;
	col -= scanline_strength * (0.5 + 0.5 * sin(uv.y * 900.0));
	col = max(col, vec3(0.0));
	COLOR = vec4(col, 1.0);
}
