extends CanvasLayer
## 全畫面魚眼鏡效果：只有桶形變形（沒有暗角、色差等其他效果）。按 V 開關。
## 世界與名牌會被扭曲，介面（HUD）不會。滑鼠瞄準用 warp_pos() 校正。

const K := 0.35
static var enabled := true

var rect := ColorRect.new()
var mat := ShaderMaterial.new()

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float k = 0.35;
uniform float aspect = 1.7778;
uniform vec2 pix_res = vec2(1280.0, 720.0);

vec2 warp(vec2 uv) {
	vec2 d = uv - 0.5;
	vec2 da = vec2(d.x * aspect, d.y);
	float r2 = dot(da, da);
	vec2 dc = vec2(0.5 * aspect, 0.5);
	float rc2 = dot(dc, dc);
	return 0.5 + d * (1.0 + k * r2) / (1.0 + k * rc2);
}

void fragment() {
	vec2 src = clamp(warp(SCREEN_UV), 0.0, 1.0);
	// 對齊 3D 畫面的像素格，放大時是硬邊方塊而不是模糊
	src = (floor(src * pix_res) + 0.5) / pix_res;
	vec3 col = texture(screen_tex, src).rgb;
	// 調色：提高對比與飽和，暗部偏青、亮部偏橙
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, 1.15);
	col = (col - 0.5) * 1.1 + 0.5;
	col += mix(vec3(-0.02, 0.01, 0.04), vec3(0.04, 0.015, -0.03), smoothstep(0.2, 0.8, lum));
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
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

func _process(_delta: float) -> void:
	mat.set_shader_parameter("k", K)
	var vs := get_viewport().get_visible_rect().size
	mat.set_shader_parameter("aspect", vs.x / vs.y)
	var root := get_tree().root
	mat.set_shader_parameter("pix_res", (Vector2(root.get_window().size) * root.scaling_3d_scale).round())
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
