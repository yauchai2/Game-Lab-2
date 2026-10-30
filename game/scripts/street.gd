extends Node3D
## Builds the low-poly street arena from flat-colour boxes (palette from docs/art/style-guide.md).

const ASPHALT := Color("3B3F4E")
const CHALK := Color("E7DFC9")
const SIDEWALK := Color("BCC5D4")
const NAVY := Color("292D3B")
const BUILDING_COLORS: Array[Color] = [
	Color("CC6657"), Color("75C7B0"), Color("E7DFC9"), Color("9B8ACC"),
	Color("8C9871"), Color("D6D573"), Color("859AC1"),
]
const SKY := Color("52B7F0")

var rng := RandomNumberGenerator.new()

## 擋住鏡頭與玩家之間視線的建築與樹會變半透明。
const FADE_ALPHA := 0.2
const FADE_MARGIN := 0.8
var occluders: Array = []

func _register_occluder(node: Node3D, box: AABB) -> void:
	occluders.append({"node": node, "box": box.grow(FADE_MARGIN), "alpha": 1.0, "mats": []})

func _collect_mats(o: Dictionary) -> Array:
	if o["mats"].is_empty():
		for c in o["node"].find_children("*", "MeshInstance3D", true, false):
			if c.material_override is StandardMaterial3D:
				o["mats"].append(c.material_override)
	return o["mats"]

func _set_alpha(o: Dictionary, a: float) -> void:
	var was: float = o["alpha"]
	o["alpha"] = a
	for m: StandardMaterial3D in _collect_mats(o):
		if a < 0.999:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color.a = a
		elif was < 0.999:
			m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			m.albedo_color.a = 1.0

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var player := get_tree().get_first_node_in_group("player")
	if cam == null or player == null:
		return
	var a := cam.global_position
	var b: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	for o in occluders:
		var target := FADE_ALPHA if (o["box"] as AABB).intersects_segment(a, b) != null else 1.0
		var cur: float = o["alpha"]
		if not is_equal_approx(cur, target):
			_set_alpha(o, move_toward(cur, target, delta * 4.0))

func _ready() -> void:
	rng.seed = 7
	_setup_environment()
	_build_ground()
	_build_buildings()
	_build_props()
	_build_clutter()
	_texture_floor()

## 程式生成嘅手繪感貼圖（灰階，會乘上顏色）：筆觸、橫向牆板、柏油碎石。
var textures := {}

func _tex(kind: String) -> ImageTexture:
	if textures.has(kind):
		return textures[kind]
	var n := FastNoiseLite.new()
	n.seed = 11
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var v := 0.9 + n.get_noise_2d(x * 2.2, y * 0.5) * 0.12 + n.get_noise_2d(x * 0.6 + 40.0, y * 0.6) * 0.06
			if kind == "wall" and y % 8 == 0:
				v *= 0.86
			elif kind == "asphalt":
				var roll := r.randf()
				if roll < 0.035:
					v *= 1.35
				elif roll < 0.07:
					v *= 0.72
			img.set_pixel(x, y, Color(v, v, v))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	textures[kind] = t
	return t

func _mat(color: Color, tex_kind := "grain") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _tex(tex_kind)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * (0.45 if tex_kind != "asphalt" else 0.35)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 1.0
	return m

func _box(pos: Vector3, size: Vector3, color: Color, collide := false, parent: Node = null, tex_kind := "grain") -> Node3D:
	var node: Node3D
	if collide:
		node = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		node.add_child(shape)
	else:
		node = Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color, tex_kind)
	node.add_child(mi)
	node.position = pos
	(parent if parent != null else self).add_child(node)
	return node

func _setup_environment() -> void:
	# 橙紅黃昏天空、青色環境光、暖色低角度太陽（參考 SLUMLORDZ SANDWICH）。
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("2B6A84")
	sky_mat.sky_horizon_color = Color("FF7A3D")
	sky_mat.ground_horizon_color = Color("D85A34")
	sky_mat.ground_bottom_color = Color("4A2A3A")
	sky_mat.sky_curve = 0.18
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7FA9C4")
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("F29A63")
	env.fog_density = 0.0015
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun: DirectionalLight3D = get_parent().get_node_or_null("Sun")
	if sun:
		sun.rotation_degrees = Vector3(-30, -40, 0)
		sun.light_color = Color("FFC27F")
		sun.light_energy = 0.75
		sun.shadow_enabled = true

func _build_ground() -> void:
	# Road with centre dashes, sidewalk strips and a crosswalk.
	_box(Vector3(0, 0.015, -17.5), Vector3(60, 0.03, 5), SIDEWALK)
	_box(Vector3(0, 0.015, 19.0), Vector3(60, 0.03, 4), SIDEWALK)
	for i in range(-5, 6):
		_box(Vector3(i * 4.0, 0.02, 0.0), Vector3(2.0, 0.03, 0.25), CHALK)
	for i in range(-3, 4):
		_box(Vector3(10.0, 0.02, i * 1.1), Vector3(3.0, 0.03, 0.55), CHALK)

func _facade(pos: Vector3, size: Vector3, color: Color, face_dir: Vector3) -> void:
	var group := Node3D.new()
	add_child(group)
	_register_occluder(group, AABB(pos - size / 2.0, size))
	_box(pos, size, color, true, group, "wall")
	_sign(pos, size, face_dir, group)
	# windows on the visible face
	var cols := maxi(int(size.x / 2.2) if absf(face_dir.z) > 0.5 else int(size.z / 2.2), 1)
	var rows := maxi(int((size.y - 3.0) / 2.6), 1)
	for r in rows:
		for c in cols:
			var along := (c + 0.5) / cols - 0.5
			var y := 3.2 + r * 2.6
			var offset := face_dir * (size.z / 2.0 + 0.04) if absf(face_dir.z) > 0.5 else face_dir * (size.x / 2.0 + 0.04)
			var win_pos := pos - Vector3(0, size.y / 2.0, 0) + Vector3(0, y, 0) + offset
			var win_size := Vector3(1.2, 1.3, 0.08)
			if absf(face_dir.z) > 0.5:
				win_pos.x += along * size.x
			else:
				win_pos.z += along * size.z
				win_size = Vector3(0.08, 1.3, 1.2)
			_box(win_pos, win_size, NAVY, false, group)
	# shop awning on the ground floor
	var awning_color: Color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
	if absf(face_dir.z) > 0.5:
		_box(pos - Vector3(0, size.y / 2.0 - 2.6, 0) + face_dir * (size.z / 2.0 + 0.5), Vector3(size.x * 0.8, 0.25, 1.2), awning_color, false, group)
	else:
		_box(pos - Vector3(0, size.y / 2.0 - 2.6, 0) + face_dir * (size.x / 2.0 + 0.5), Vector3(1.2, 0.25, size.z * 0.8), awning_color, false, group)

func _build_buildings() -> void:
	# back row (z-), seen from the camera
	var x := -30.0
	while x < 30.0:
		var w := rng.randf_range(6.0, 9.0)
		var h := rng.randf_range(8.0, 16.0)
		var color: Color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
		_facade(Vector3(x + w / 2.0, h / 2.0, -23.0), Vector3(w, h, 6.0), color, Vector3(0, 0, 1))
		x += w + 0.2
	# left and right rows
	for side in [-1, 1]:
		var z := -20.0
		while z < 21.0:
			var d := rng.randf_range(6.0, 9.0)
			var h := rng.randf_range(6.0, 12.0)
			var color: Color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
			_facade(Vector3(side * 24.0, h / 2.0, z + d / 2.0), Vector3(6.0, h, d), color, Vector3(-side, 0, 0))
			z += d + 0.2

func _build_props() -> void:
	# lamp posts
	for p in [Vector3(-12, 0, -15), Vector3(12, 0, -15), Vector3(-16, 0, 17), Vector3(16, 0, 17)]:
		_box(p + Vector3(0, 2.5, 0), Vector3(0.25, 5.0, 0.25), NAVY, true)
		_box(p + Vector3(0, 5.1, 0), Vector3(1.0, 0.3, 0.5), Color("D6D573"))
	# trees
	for p in [Vector3(-6, 0, -15.5), Vector3(5, 0, -15.5), Vector3(-19, 0, 6), Vector3(19, 0, -6)]:
		var tree := Node3D.new()
		add_child(tree)
		_register_occluder(tree, AABB(p + Vector3(-1.2, 0.0, -1.2), Vector3(2.4, 5.0, 2.4)))
		_box(p + Vector3(0, 1.0, 0), Vector3(0.4, 2.0, 0.4), Color("7A5A44"), true, tree)
		var crown := _box(p + Vector3(0, 3.0, 0), Vector3(2.4, 2.2, 2.4), Color("35676B"), false, tree)
		crown.rotation.y = 0.6
		var top := _box(p + Vector3(0, 4.4, 0), Vector3(1.6, 1.2, 1.6), Color("75C7B0"), false, tree)
		top.rotation.y = 0.2
	# parked yellow car
	_box(Vector3(-11, 0.7, -11.5), Vector3(4.2, 1.1, 2.0), Color("D6D573"), true)
	_box(Vector3(-11.3, 1.55, -11.5), Vector3(2.2, 0.8, 1.8), NAVY)
	# vending machines and crates along the back sidewalk
	_box(Vector3(8, 1.0, -15.8), Vector3(1.0, 2.0, 0.8), Color("CC6657"), true)
	_box(Vector3(9.4, 1.0, -15.8), Vector3(1.0, 2.0, 0.8), Color("9B8ACC"), true)
	_box(Vector3(-3, 0.5, -15.5), Vector3(1.0, 1.0, 1.0), Color("859AC1"), true)
	_box(Vector3(-1.8, 0.4, -15.5), Vector3(0.8, 0.8, 0.8), Color("D6D573"), true)

func _texture_floor() -> void:
	var mesh: MeshInstance3D = get_parent().get_node_or_null("Floor/Mesh")
	if mesh:
		mesh.material_override = _mat(ASPHALT, "asphalt")

# --- 招牌、電線、雜物：混用漢字、假名、拉丁字母同虛構符號 ---

const SIGN_TEXTS := ["ラーメン 麵", "24H 便利店", "雑貨 STORE", "回收 ⌬ RECYCLE", "PAWN 當", "ネオン ◇ 酒", "TK-075", "整件回收", "ERRO ∴ 零", "食 ✦ 堂"]
const SIGN_COLORS: Array[Color] = [Color("FF5FA2"), Color("5FE0E8"), Color("FFB347"), Color("A6FF8F"), Color("FFF07A")]

func _emissive(color: Color, energy := 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _sign(pos: Vector3, size: Vector3, face_dir: Vector3, parent: Node) -> void:
	if rng.randf() > 0.75:
		return
	var along_z := absf(face_dir.z) > 0.5
	var half := size.z / 2.0 if along_z else size.x / 2.0
	var base := pos - Vector3(0, size.y / 2.0, 0) + face_dir * (half + 0.08) + Vector3(0, 1.9, 0)
	var board_w := minf(size.x if along_z else size.z, 6.0) * 0.5
	var color: Color = SIGN_COLORS[rng.randi() % SIGN_COLORS.size()]
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(board_w, 0.7, 0.1) if along_z else Vector3(0.1, 0.7, board_w)
	board.mesh = bm
	board.material_override = _mat(NAVY)
	board.position = base
	parent.add_child(board)
	var label := Label3D.new()
	label.text = SIGN_TEXTS[rng.randi() % SIGN_TEXTS.size()]
	label.font_size = 48
	label.pixel_size = 0.0085
	label.outline_size = 0
	label.modulate = color
	label.shaded = false
	label.no_depth_test = false
	label.position = base + face_dir * 0.07
	label.rotation.y = 0.0 if face_dir.z > 0.5 else (PI if face_dir.z < -0.5 else (PI / 2.0 if face_dir.x > 0.5 else -PI / 2.0))
	parent.add_child(label)

func _pole(p: Vector3) -> Vector3:
	_box(p + Vector3(0, 4.5, 0), Vector3(0.3, 9.0, 0.3), Color("5A4B45"), true)
	_box(p + Vector3(0, 8.3, 0), Vector3(2.4, 0.15, 0.15), Color("5A4B45"))
	return p + Vector3(0, 8.3, 0)

func _wire(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) / 2.0 - Vector3(0, 0.35, 0)
	for seg in [[a, mid], [mid, b]]:
		var from: Vector3 = seg[0]
		var to: Vector3 = seg[1]
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.04, 0.04, from.distance_to(to))
		mi.mesh = bm
		mi.material_override = _mat(Color("1E1B22"))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.position = (from + to) / 2.0
		mi.look_at(to, Vector3.UP)

func _build_clutter() -> void:
	# 電線桿沿著兩側人行道，電線橫跨街道
	var tops_l: Array = []
	var tops_r: Array = []
	for z in [-14.0, -3.0, 6.0]:
		tops_l.append(_pole(Vector3(-17.5, 0, z)))
		tops_r.append(_pole(Vector3(17.5, 0, z)))
	for i in tops_l.size():
		if i > 0:
			for off in [-0.9, 0.0, 0.9]:
				_wire(tops_l[i - 1] + Vector3(off, 0, 0), tops_l[i] + Vector3(off, 0, 0))
				_wire(tops_r[i - 1] + Vector3(off, 0, 0), tops_r[i] + Vector3(off, 0, 0))
		if i < 2:
			_wire(tops_l[i] + Vector3(0.9, 0, 0), tops_r[i] + Vector3(-0.9, 0, 0))
	# 販賣機（發光）、單車、垃圾桶、雜物堆
	for v in [[Vector3(-16.4, 0, -4.0), Color("5FE0E8")], [Vector3(-16.4, 0, -5.2), Color("FF5FA2")], [Vector3(16.4, 0, 6.0), Color("FFB347")]]:
		var pos: Vector3 = v[0]
		_box(pos + Vector3(0, 1.0, 0), Vector3(0.9, 2.0, 0.8), Color("E7DFC9"), true)
		var face := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.05, 1.2, 0.6)
		face.mesh = fm
		face.material_override = _emissive(v[1])
		face.position = pos + Vector3(0.48 if pos.x < 0 else -0.48, 1.25, 0)
		add_child(face)
	for p in [Vector3(14.5, 0, -8.0), Vector3(-14.8, 0, 13.0), Vector3(15.5, 0, 14.0)]:
		_box(p + Vector3(0, 0.45, 0), Vector3(1.5, 0.35, 0.5), Color("3A3F4A"), true)
		_box(p + Vector3(0.6, 0.8, 0), Vector3(0.2, 0.7, 0.45), Color("CC6657"))
		_box(p + Vector3(-0.65, 0.2, 0), Vector3(0.4, 0.4, 0.4), Color("1E1B22"))
		_box(p + Vector3(0.65, 0.2, 0), Vector3(0.4, 0.4, 0.4), Color("1E1B22"))
	for p in [Vector3(-16.6, 0, 3.0), Vector3(16.6, 0, -2.0), Vector3(-16.6, 0, 11.0)]:
		_box(p + Vector3(0, 0.55, 0), Vector3(0.7, 1.1, 0.7), Color("5D8C73"), true)
		_box(p + Vector3(0.7, 0.3, 0.2), Vector3(0.9, 0.6, 0.9), Color("B8895B"), true)
