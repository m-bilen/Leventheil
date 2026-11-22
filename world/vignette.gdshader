shader_type canvas_item;

uniform float strength = 0.55;
uniform float inner = 0.35;
uniform float outer = 0.85;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.0, 0.55);
	float d = length(p) * 2.0;
	float v = smoothstep(inner, outer, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * strength);
}