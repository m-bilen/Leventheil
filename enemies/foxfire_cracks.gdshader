shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 glow_color : source_color = vec3(0.25, 1.0, 0.7);
uniform float glow_energy = 1.0;
uniform float glow_scale = 0.6;
uniform float vein_width = 1.2;
uniform vec2 crack_scale = vec2(2.0, 0.6);
uniform float patch_cut = 0.5;
uniform sampler2D noise : repeat_enable;

void fragment() {
	float n = texture(noise, UV * crack_scale).r;
	float edge = abs(n - 0.5) / max(fwidth(n), 0.0001);
	float crack = 1.0 - smoothstep(0.0, vein_width, edge);
	float p = texture(noise, UV * vec2(1.0, 0.5) + vec2(0.37, 0.11)).r;
	float patch_mask = smoothstep(patch_cut, patch_cut + 0.15, p);
	ALBEDO = glow_color * crack * patch_mask * glow_energy * glow_scale;
}
