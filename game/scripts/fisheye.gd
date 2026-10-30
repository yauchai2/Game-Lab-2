extends CanvasLayer
## 全畫面魚眼鏡效果：桶形變形加邊緣微暗。按 V 開關。
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
	vec3 col = texture(screen_tex, clamp(warp(uv), 0.0, 1.0)).rgb;
	// 鏡頭邊緣略暗
	vec2 dv = uv - 0.5;
	col *= 1.0 - smoothstep(0.3, 0.8, dot(dv, dv) * 1.5) * 0.45;
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

func _process(_delta: float) -> void:
	mat.set_shader_parameter("k", K)
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
