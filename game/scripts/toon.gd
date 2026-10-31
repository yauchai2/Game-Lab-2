extends Node
## 全局卡通渲染：
## 1. 所有標準材質改用卡通漫反射（分層光影、無高光）；新生成的物件自動套用。
## 2. 依深度圖畫輪廓線（相機前一塊全螢幕方塊，Compatibility 渲染器可用）。
## 設定：GameSettings.v["toon"]、v["outline"]（設定頁可開關）。

const GS := preload("res://game/scripts/game_settings.gd")

const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, blend_mix;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec4 line_color : source_color = vec4(0.07, 0.08, 0.11, 1.0);
uniform float thickness = 1.0;
uniform float threshold = 0.06;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float lin(vec2 uv, float d, mat4 inv_proj) {
	vec4 p = inv_proj * vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
	return -p.z / p.w;
}

void fragment() {
	vec2 px = thickness / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float c = lin(uv, texture(depth_tex, uv).x, INV_PROJECTION_MATRIX);
	float e = 0.0;
	vec2 offs[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	for (int i = 0; i < 4; i++) {
		vec2 u2 = uv + offs[i];
		float n = lin(u2, texture(depth_tex, u2).x, INV_PROJECTION_MATRIX);
		e = max(e, abs(n - c) / max(min(n, c), 0.1));
	}
	float a = smoothstep(threshold, threshold * 2.0, e);
	ALBEDO = line_color.rgb;
	ALPHA = a * line_color.a;
}
"""

var quad := MeshInstance3D.new()
var _toon_on := false

func _ready() -> void:
	add_to_group("toon")
	var sh := Shader.new()
	sh.code = OUTLINE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	quad.mesh = q
	quad.material_override = mat
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		cam = get_parent().get_node_or_null("Camera3D")
	if cam != null:
		cam.add_child(quad)
		quad.position = Vector3(0, 0, -0.5)
	get_tree().node_added.connect(_on_node_added)
	refresh()

## 設定改變後呼叫。
func refresh() -> void:
	quad.visible = GS.v["outline"] == 1
	_toon_on = GS.v["toon"] == 1
	_walk(get_parent())

func _on_node_added(n: Node) -> void:
	if n is MeshInstance3D:
		_toonify.call_deferred(n)

func _walk(n: Node) -> void:
	if n is MeshInstance3D:
		_toonify(n)
	for c in n.get_children():
		_walk(c)

func _toonify(mi: MeshInstance3D) -> void:
	if not is_instance_valid(mi) or mi.mesh == null:
		return
	var mats: Array = []
	if mi.material_override != null:
		mats.append(mi.material_override)
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i)
		if m != null:
			mats.append(m)
	for m in mats:
		if m is StandardMaterial3D:
			if _toon_on:
				m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
			else:
				m.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
				m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
