shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 glow_color : source_color = vec3(1.0, 0.6, 0.15);
uniform float glow_energy = 2.0;
uniform vec3 maw_center;
uniform float maw_radius = 1.3;
uniform float glow_scale = 0.12;
uniform sampler2D noise : repeat_enable;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = distance(world_pos, maw_center) / maw_radius;
	float n = texture(noise, world_pos.xz * 0.8).r;
	float glow = pow(clamp(1.0 - d, 0.0, 1.0), 1.5) * (0.6 + 0.8 * n);
	ALBEDO = glow_color * glow * glow_energy * glow_scale;
}