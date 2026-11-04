shader_type sky;
// Static, hard-edged cloud shapes. No time dependency or photographic textures.
uniform vec3 sky_color : source_color = vec3(0.141, 0.62, 0.827);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.969, 0.878);
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}
void sky() {
	vec3 base = mix(sky_color * 1.13, sky_color, smoothstep(0.0, 0.65, EYEDIR.y));
	vec2 p = EYEDIR.xz / max(EYEDIR.y + 0.24, 0.06) * 2.0;
	float shape = noise(p) * 0.7 + noise(p * 2.5) * 0.3;
	float cloud = step(0.61, shape) * smoothstep(0.03, 0.13, EYEDIR.y);
	COLOR = mix(base, cloud_color, cloud);
}
