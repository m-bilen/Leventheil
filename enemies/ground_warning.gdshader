shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 color : source_color = vec4(0.55, 0.25, 0.8, 1.0);
uniform float progress = 0.0;
uniform sampler2D noise: repeat_enable;
uniform float edge_width = 0.08;
uniform float vein_scale = 3.0;
uniform float front_width = 0.04;
uniform float heave_height = 0.12;

void vertex(){
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = texture(noise, UV * 2.0).r;
	float heave = smoothstep(0.6, 0.9, r) * smoothstep(1.0, 0.9, r);
	VERTEX.y += heave * heave_height * (0.4 + 0.6 * progress) * (0.6 + 0.8 * n); 
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float n = texture(noise, UV * 2.0 + vec2(TIME * 0.05)).r;
	float edge_r = 0.9 + (n - 0.5) * 0.15;
	float ring = smoothstep(edge_width, 0.0, abs(r - edge_r));

	float front_r = edge_r * (1.0 - progress);
	float behind_front = smoothstep(front_r - 0.05, front_r + 0.05, r) * step(r, edge_r);
	float vn = texture(noise, UV * vein_scale).r;
	float vein = 1.0 - smoothstep(0.0, 0.04, abs(vn - 0.5));
	float front = smoothstep(front_width, 0.0, abs(r - front_r));

	float fill = behind_front * 0.15;
	float stain = smoothstep(edge_r, edge_r -0.3, r) * n * 0.12;
	float purple = ring * mix(0.3, 1.0, progress) + stain + fill + vein * behind_front * 0.6 + front * 0.8;
	float pit = smoothstep(edge_r, 0.0, r) * (0.25 + 0.35 * progress);
	float a = clamp(purple + pit, 0.0, 1.0);
	ALBEDO = mix(vec3(0.02, 0.0, 0.03), color.rgb, clamp(purple / max(a, 0.001), 0.0, 1.0));
	ALPHA = a * step(r, 1.0);
}
