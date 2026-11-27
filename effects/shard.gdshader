shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 core_color : source_color = vec3(0.07, 0.05, 0.04);
uniform float rim_start = 0.2;
uniform float rim_energy = 1.2;

void fragment() {
	float rim = smoothstep(rim_start, 1.0, UV.x);
	ALBEDO = mix(core_color, COLOR.rgb * rim_energy, rim);
}