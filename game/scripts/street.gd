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

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	return m

func _box(pos: Vector3, size: Vector3, color: Color, collide := false, parent: Node = null) -> Node3D:
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
	mi.material_override = _mat(color)
	node.add_child(mi)
	node.position = pos
	(parent if parent != null else self).add_child(node)
	return node

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("F4E9D6")
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun: DirectionalLight3D = get_parent().get_node_or_null("Sun")
	if sun:
		sun.light_color = Color("FFF1D6")
		sun.light_energy = 0.7
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
	_box(pos, size, color, true, group)
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
