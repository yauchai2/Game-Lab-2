extends CanvasLayer
## 全畫面 VHS 魚眼鏡效果：桶形變形、色差、掃描線、追蹤抖動、噪點、暈影。按 V 開關。
## 世界與名牌會被扭曲，介面（HUD）不會。滑鼠瞄準用 warp_pos() 校正。

const K := 0.10
static var enabled := true
static var kick := 0.0

var rect := ColorRect.new()
var mat := ShaderMaterial.new()
var time := 0.0

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float k = 0.10;
uniform float aspect = 1.7778;
uniform float t = 0.0;
uniform float kick = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 warp(vec2 uv) {
	vec2 d = uv - 0.5;
	vec2 da = vec2(d.x * aspect, d.y);
	float r2 = dot(da, da);
	vec2 dc = vec2(0.5 * aspect, 0.5);
	float rc2 = dot(dc, dc);
	return 0.5 + d * (1.0 + k * r2) / (1.0 + k * rc2);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 w = warp(uv);
	// 追蹤抖動：偶爾有幾條橫帶左右偏移
	float row = floor(uv.y * 90.0);
	float glitch = step(0.985, hash(vec2(row, floor(t * 4.0)))) * (hash(vec2(row, t)) - 0.5) * 0.02;
	// 慢速滾動的亮帶
	float bar = smoothstep(0.0, 0.06, fract(uv.y * 0.6 - t * 0.05)) * (1.0 - smoothstep(0.06, 0.14, fract(uv.y * 0.6 - t * 0.05)));
	w.x += glitch + kick * (hash(vec2(row, t * 20.0)) - 0.5) * 0.012 + sin(uv.y * 40.0 + t * 3.0) * 0.0006;
	float ca = 0.0022 + bar * 0.002 + kick * 0.008;
	vec3 col;
	col.r = texture(screen_tex, clamp(w + vec2(ca, 0.0), 0.0, 1.0)).r;
	col.g = texture(screen_tex, clamp(w, 0.0, 1.0)).g;
	col.b = texture(screen_tex, clamp(w - vec2(ca, 0.0), 0.0, 1.0)).b;
	// 掃描線與噪點
	col *= 0.93 + 0.07 * sin(uv.y * 3.14159 * 360.0);
	col += (hash(uv * vec2(640.0, 360.0) + fract(t) * 91.0) - 0.5) * 0.07;
	col += bar * 0.05;
	// 褪色與偏暖
	float g = dot(col, vec3(0.3, 0.59, 0.11));
	col = mix(col, vec3(g), 0.12) * vec3(1.03, 1.0, 0.95);
	// 暈影
	vec2 dv = uv - 0.5;
	col *= 1.0 - smoothstep(0.25, 0.75, dot(dv, dv) * 1.6);
	COLOR = vec4(col, 1.0);
}
"""

func _ready() -> void:
	layer = 0
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	rect.material = mat
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = enabled
	add_child(rect)

func _process(delta: float) -> void:
	time += delta
	mat.set_shader_parameter("t", time)
	mat.set_shader_parameter("k", K)
	kick = move_toward(kick, 0.0, delta * 3.0)
	mat.set_shader_parameter("kick", kick)
	rect.visible = enabled

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V:
		enabled = not enabled

## 滑鼠在（扭曲後）畫面上的位置 → 對應 3D 畫面（未扭曲）的位置。關掉濾鏡時原樣返回。
static func warp_pos(pos: Vector2, view_size: Vector2) -> Vector2:
	if not enabled:
		return pos
	var uv := pos / view_size
	var aspect := view_size.x / view_size.y
	var d := uv - Vector2(0.5, 0.5)
	var da := Vector2(d.x * aspect, d.y)
	var dc := Vector2(0.5 * aspect, 0.5)
	var w := Vector2(0.5, 0.5) + d * (1.0 + K * da.length_squared()) / (1.0 + K * dc.length_squared())
	return w * view_size
