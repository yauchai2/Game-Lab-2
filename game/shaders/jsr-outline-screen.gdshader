shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled;
// Screen-space depth edge lines for boxy scenery (inverted hulls break on hard edges).
// Width is 1 px in render pixels. Normals are unavailable in the Compatibility renderer,
// so only depth discontinuities are detected.

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float ortho_threshold = 0.05;   // metres, orthographic camera
uniform float persp_relative = 0.008;   // fraction of inverse depth, perspective camera
uniform float concave_max = 6.0;        // concave creases are small; larger negative jumps are far-side silhouettes
uniform float line_scale = 1.0;         // line width in render pixels (set from render height)

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// Depth is sampled directly in fragment(): the Compatibility renderer only binds
	// the depth texture when it is used here, not inside a helper function.
	// A plane is linear in view z (orthographic) or in 1/z (perspective), so the second
	// difference is ~0 on flat faces and large on silhouettes and creases. Only the
	// nearer side (positive second difference in z) draws, keeping lines 1 px wide.
	bool ortho = PROJECTION_MATRIX[3][3] > 0.5;
	vec2 px = line_scale / VIEWPORT_SIZE;
	vec2 offs[5] = vec2[](vec2(0.0), vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	float q[5];
	for (int i = 0; i < 5; i++) {
		vec2 uv = SCREEN_UV + offs[i];
		float d = texture(depth_tex, uv).r;
		vec4 v = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
		float z = -v.z / v.w;
		q[i] = ortho ? z : 1.0 / z;
	}
	float lim = ortho ? ortho_threshold : persp_relative * q[0];
	float lap_h = q[1] + q[2] - 2.0 * q[0];
	float lap_v = q[3] + q[4] - 2.0 * q[0];
	// z second difference > 0 equals 1/z second difference < 0.
	float sign_dir = ortho ? 1.0 : -1.0;
	float sh = sign_dir * lap_h;
	float sv = sign_dir * lap_v;
	// Positive: convex edge or near side of a silhouette. Small negative: concave corner
	// (wall base, window recess).
	float e = 0.0;
	e = max(e, step(lim, sh));
	e = max(e, step(lim, sv));
	e = max(e, step(lim, -sh) * step(-sh, concave_max * lim));
	e = max(e, step(lim, -sv) * step(-sv, concave_max * lim));
	ALBEDO = line_color.rgb;
	ALPHA = e;
}
