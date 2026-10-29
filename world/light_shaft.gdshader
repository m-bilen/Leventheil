shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.9, 0.72, 1.0);
uniform float strength = 0.12;

void fragment(){
	float facing = abs(dot(NORMAL, VIEW));
	float edge = pow(facing, 3.0);
	float vertical = smoothstep(0.0, 0.08, UV.y) * smoothstep(1.0, 0.5, UV.y);	ALBEDO = color.rgb;
	ALPHA = edge * vertical * strength;
}
