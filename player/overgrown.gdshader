shader_type spatial;

uniform sampler2D skin_texture : source_color;
uniform vec3 skin_tint : source_color = vec3(0.62, 0.68, 0.58);
uniform vec3 bark_tint : source_color = vec3(0.75, 0.62, 0.48);
uniform float desaturate = 0.7;
uniform sampler2D bark_texture : source_color, repeat_enable;
uniform sampler2D patch_noise : repeat_enable;
uniform float bark_amount = 0.45;
uniform float bark_scale = 6.0;
uniform vec3 vein_color : source_color = vec3(0.49, 1.0, 0.42);
uniform float vein_width = 1.5;
uniform float vein_energy = 1.5;


void fragment() {
	vec3 skin = texture(skin_texture, UV).rgb;
	float gray = dot(skin, vec3(0.299, 0.587, 0.114));
	skin = mix(skin, vec3(gray), desaturate) * skin_tint;
	float n = texture(patch_noise, UV).r;
	float threshold = 1.0 - bark_amount;
	vec3 bark = texture(bark_texture, UV * bark_scale).rgb * bark_tint;
	float edge = (n - threshold) / max(fwidth(n), 0.0001);
	float vein = 1.0 - smoothstep(0.0, vein_width, abs(edge));
	float bark_mask = smoothstep(-1.0, 1.0, edge);
	ALBEDO = mix(skin, bark, bark_mask);
	EMISSION = vein_color * vein * vein_energy;
	ROUGHNESS = 0.85;
	RIM = 0.5;
	RIM_TINT = 0.5;
}
