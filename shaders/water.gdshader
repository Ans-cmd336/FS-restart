shader_type spatial;

render_mode blend_premul_alpha;

uniform vec4 albedo: source_color;
uniform sampler2D normal: source_color;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.2;
	ALPHA = 0.7;
	NORMAL_MAP = texture(normal,vec2(1000,1000)+UV*TIME*0.2).xyz;
}