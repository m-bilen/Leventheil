shader_type spatial;
render_mode cull_disabled;

uniform vec3 glow_color : source_color = vec3(1.0, 0.6, 0.15);
uniform float glow_energy = 2.0;
uniform vec3 wall_color : source_color = vec3(0.07, 0.05, 0.04);
uniform float well_height = 0.7;
uniform float glow_scale = 0.35;
uniform sampler2D noise : repeat_enable;

varying float depth;

void vertex() {
	depth = clamp((well_height * 0.5 - VERTEX.y) / well_height, 0.0, 1.0);
}

void fragment() {
	float n = texture(noise, UV * vec2(3.0, 1.0)).r;
	float glow = pow(depth, 1.5) * (0.6 + 0.8 * n);
	ALBEDO = wall_color;
	EMISSION = glow_color * glow * glow_energy * glow_scale;
}