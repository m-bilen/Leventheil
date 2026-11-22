shader_type spatial;
render_mode cull_disabled;

uniform vec4 color_a : source_color = vec4(0.29, 0.26, 0.20, 1.0);
uniform vec4 color_b : source_color = vec4(0.21, 0.19, 0.15, 1.0);

varying float shade;

void vertex() {
	vec2 seed = MODEL_MATRIX[3].xz;
	shade = fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float half_width = sin(UV.y * PI) * 0.5;
	float d = abs(UV.x - 0.5);
	if (d > half_width) {
		discard;
	}
	float vein = smoothstep(0.03, 0.0, d);
	ALBEDO = mix(color_a.rgb, color_b.rgb, shade) * (1.0 - vein * 0.35);
	ROUGHNESS = 1.0;
}