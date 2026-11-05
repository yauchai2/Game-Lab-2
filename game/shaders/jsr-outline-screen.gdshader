shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled;
// Screen-space depth edge lines for boxy scenery (inverted hulls break on hard edges).
// Width is 1 px in render pixels. Normals are unavailable in the Compatibility renderer,
// so only depth discontinuities are detected.

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float threshold = 0.12;
uniform float relative_threshold = 0.012;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// Depth is sampled directly in fragment(): the Compatibility renderer only binds
	// the depth texture when it is used here, not inside a helper function.
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec2 offs[5] = vec2[](vec2(0.0), vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	float z[5];
	for (int i = 0; i < 5; i++) {
		vec2 uv = SCREEN_UV + offs[i];
		float d = texture(depth_tex, uv).r;
		vec4 v = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
		z[i] = -v.z / v.w;
	}
	float limit = threshold + relative_threshold * z[0];
	float e = 0.0;
	for (int i = 1; i < 5; i++) {
		e = max(e, step(limit, abs(z[i] - z[0])));
	}
	ALBEDO = line_color.rgb;
	ALPHA = e;
}
