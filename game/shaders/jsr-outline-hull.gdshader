shader_type spatial;
render_mode unshaded, cull_front;
// Inverted hull with a constant width in render pixels (characters: 2 px).

uniform float width_px = 2.0;
uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 n = (PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xy;
	if (length(n) > 0.0001) {
		clip.xy += normalize(n) * width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = line_color.rgb;
}
