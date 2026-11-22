shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.55, 0.02, 0.02, 1.0);
uniform float flash = 0.0;
uniform float low_health = 0.0;
uniform vec4 shield_color : source_color = vec4(0.85, 0.8, 0.72, 1.0);
uniform float shield_flash = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.0, 0.6);
	float d = length(p) * 2.0;
	float edge = smoothstep(0.45, 1.05, d);
	float red = edge * (flash * 0.6 + low_health * 0.35);
	float bone = edge * shield_flash * 0.3;
	float a = red + bone;
	vec3 rgb = mix(shield_color.rgb, color.rgb, red / max(a, 0.001));
	COLOR = vec4(rgb, a);}