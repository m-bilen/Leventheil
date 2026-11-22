shader_type spatial;
render_mode blend_mix, depth_draw_never;

uniform vec4 dark_color : source_color = vec4(0.13, 0.2, 0.08, 1.0);
uniform vec4 light_color : source_color = vec4(0.3, 0.42, 0.16, 1.0);
uniform float strength = 0.9;
uniform sampler2D noise : repeat_enable;

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float big = texture(noise, world_xz * 0.25).r;
	float fine = texture(noise, world_xz * 2.5).r;
	float mask = smoothstep(1.0, 0.45, r + (big - 0.5) * 1.0);
	float clumps = smoothstep(0.35, 0.65, fine);
	ALBEDO = mix(dark_color.rgb, light_color.rgb, clumps);
	ROUGHNESS = 1.0;
	ALPHA = mask * (0.5 + 0.5 * clumps) * strength;
}