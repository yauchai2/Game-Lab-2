shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// JSR test: three hard bands from N.L. Thresholds follow docs/art/style-guide.md.

uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 shadow_tint : source_color = vec4(0.141, 0.235, 0.22, 1.0); // #243C38
uniform float threshold_lit = 0.55;
uniform float threshold_mid = 0.15;
uniform float edge_softness = 0.02;
uniform float mid_mix = 0.25;
uniform float dark_mix = 0.5;

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float d = dot(NORMAL, LIGHT) * ATTENUATION;
	float lit = smoothstep(threshold_lit - edge_softness, threshold_lit + edge_softness, d);
	float mid = smoothstep(threshold_mid - edge_softness, threshold_mid + edge_softness, d);
	float shade = mix(dark_mix, mid_mix, mid);
	shade = mix(shade, 0.0, lit);
	vec3 tinted = mix(ALBEDO, shadow_tint.rgb, shade);
	DIFFUSE_LIGHT += (tinted / max(ALBEDO, vec3(0.001))) * LIGHT_COLOR / PI;
}
