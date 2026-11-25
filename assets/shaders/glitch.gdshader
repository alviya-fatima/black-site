shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float distortion : hint_range(0.0, 1.0) = 0.0;
uniform float tint : hint_range(0.0, 1.0) = 0.0;
uniform float glitch_time : hint_range(0.0, 100.0) = 0.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME + glitch_time;
	float row = floor(uv.y * 54.0);
	float gate = step(0.62, hash12(vec2(row, floor(t * 16.0))));
	float shift = (hash12(vec2(row, floor(t * 22.0))) - 0.5) * distortion * gate * intensity;
	vec2 wobble = vec2(shift, 0.0);
	vec2 suv = fract(uv + wobble);

	float ca = 0.0045 * intensity;
	vec3 col;
	col.r = texture(screen_texture, suv + vec2(ca, 0.0)).r;
	col.g = texture(screen_texture, suv).g;
	col.b = texture(screen_texture, suv - vec2(ca, 0.0)).b;

	float cut = step(0.93, hash12(vec2(floor(uv.y * 110.0), floor(t * 11.0)))) * intensity;
	col = mix(col, vec3(0.02, 0.04, 0.024), cut * 0.55);
	float redcut = step(0.985, hash12(vec2(floor(uv.x * 90.0), floor(t * 8.0)))) * tint * intensity;
	col = mix(col, vec3(0.56, 0.045, 0.03), redcut * 0.65);

	float noise = hash12(uv * vec2(640.0, 360.0) + t * 13.0) - 0.5;
	col += noise * 0.13 * intensity;
	col = mix(col, vec3(0.64, 0.64, 0.56), step(0.997, hash12(vec2(floor(uv.y * 240.0), floor(t * 7.0)))) * intensity * 0.28);

	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
