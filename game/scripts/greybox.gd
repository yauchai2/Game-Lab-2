extends CanvasLayer
## Greybox 全灰濾鏡（自動載入）：整個畫面（含介面、標題、選角）轉為灰階，不留任何色彩。
## 目的：專注玩法與機制；用亮度、形狀、大小區分玩家／敵人／預警／可互動物。
## 美術風格押後。要恢復色彩時，將 ENABLED 改為 false。

const ENABLED := true

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(l), 1.0);
}
"""

func _ready() -> void:
	layer = 100
	if not ENABLED:
		return
	var sh := Shader.new()
	sh.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	var rect := ColorRect.new()
	rect.material = mat
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
