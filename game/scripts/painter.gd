extends RefCounted
## 手繪感貼圖：把程式生成的灰階筆觸貼圖乘上角色／敵人原本嘅顏色，唔改變顏色分區。

static var grain: ImageTexture = null

static func _grain() -> ImageTexture:
	if grain != null:
		return grain
	var n := FastNoiseLite.new()
	n.seed = 23
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 32:
			var v := 0.92 + n.get_noise_2d(x * 2.5, y * 0.8) * 0.14
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	grain = ImageTexture.create_from_image(img)
	return grain

static func apply_material(m: StandardMaterial3D) -> void:
	m.albedo_texture = _grain()
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * 1.5
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS

## 角色模型：每個表面嘅材質複製一份再貼圖（唔影響共用資源）。
static func paint(root: Node) -> void:
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			if src is StandardMaterial3D:
				var m: StandardMaterial3D = src.duplicate()
				apply_material(m)
				mi.set_surface_override_material(i, m)
