shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, shadows_disabled;

uniform vec3 glow_color : source_color = vec3(1.0, 0.6, 0.15);
uniform float glow_energy = 2.0;
uniform float rim_y = 0.65;
uniform float reach = 0.7;
uniform float vein_width = 1.2;
uniform float glow_scale = 0.12;
uniform sampler2D noise : repeat_enable;

varying float down;

void vertex() {
	down = clamp((rim_y - VERTEX.y) / reach, 0.0, 1.0);
}

void fragment() {
	float n = texture(noise, UV * vec2(4.0, 2.0)).r;
	float edge = abs(n - 0.5) / max(fwidth(n), 0.0001);
	float vein = 1.0 - smoothstep(0.0, vein_width, edge);
	float fade = (1.0 - down) * (1.0 - down);
	ALBEDO = glow_color * vein * fade * glow_energy * glow_scale;
}