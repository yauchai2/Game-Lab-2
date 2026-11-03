extends Node
## 全局卡通渲染：所有標準材質改用卡通漫反射（分層光影、無高光）；新生成的物件自動套用。
## 設定：GameSettings.v["toon"]（設定頁可開關）。

const GS := preload("res://game/scripts/game_settings.gd")

var _toon_on := false

func _ready() -> void:
	add_to_group("toon")
	get_tree().node_added.connect(_on_node_added)
	refresh()

## 設定改變後呼叫。
func refresh() -> void:
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
