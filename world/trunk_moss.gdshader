shader_type spatial;
render_mode blend_mix, depth_draw_never;

uniform vec4 moss_color : source_color = vec4(0.27, 0.4, 0.16, 1.0);
uniform float moss_height = 3.2;
uniform float strength = 0.85;
uniform sampler2D noise : repeat_enable;

varying vec3 world_pos;
varying float moss_scale;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	moss_scale = clamp(length(MODEL_MATRIX[1].xyz), 0.1, 1.0);
}

void fragment() {
	float n = texture(noise, vec2(world_pos.x + world_pos.z, world_pos.y) * 0.35).r;
	float limit = moss_height * moss_scale;
	float h = 1.0 - smoothstep(0.0, limit, world_pos.y + (n - 0.5) * 1.2 * moss_scale);
	ALBEDO = moss_color.rgb * (0.7 + 0.6 * n);
	ROUGHNESS = 1.0;
	ALPHA = h * strength;
}
