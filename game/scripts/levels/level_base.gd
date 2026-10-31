extends Node3D
## 第一章關卡共用工具：方塊、標示、人物、互動點。配色沿用 docs/art/style-guide.md。

const CHAPTER := preload("res://game/scripts/story_state.gd")
const INTERACTABLE := preload("res://game/scripts/interactable.gd")
const ENEMY_SCENE := preload("res://game/enemy.tscn")

const NAVY := Color("292D3B")
const CHALK := Color("E7DFC9")
const CORAL := Color("CC6657")
const MINT := Color("75C7B0")
const MAUVE := Color("9B8ACC")
const YELLOW := Color("D6D573")
const SLATE := Color("859AC1")
const MOSS := Color("8C9871")
const WOOD := Color("A9825F")

const PROGRESS := preload("res://game/scripts/progress.gd")
const CHARS := {
	"jax": {"name": "Jax", "color": Color("CC6657")},
	"vee": {"name": "Vee", "color": Color("9B8ACC")},
	"skye": {"name": "Skye", "color": Color("D6D573")},
	"niko": {"name": "Niko", "color": Color("8C9871")},
}

var main: Node3D
var jax: CharacterBody3D
var story: Node
var hud_ui: CanvasLayer

func _setup_refs() -> void:
	# 結構固定：Main / Street（level_loader）/ 本關卡節點
	main = get_parent().get_parent()
	jax = main.get_node("Jax")
	story = main.get_node("Story")

## 室友＝其餘三人（玩家選誰，誰就不是室友）。
func roommates() -> Array:
	var out: Array = []
	for id in ["jax", "vee", "skye", "niko"]:
		if id != PROGRESS.character:
			out.append(CHARS[id])
	return out

## 駕駛：優先 Skye，玩家是 Skye 時由 Jax 駕駛。
func driver() -> Dictionary:
	return CHARS["jax"] if PROGRESS.character == "skye" else CHARS["skye"]

func _story_hud() -> CanvasLayer:
	return story.hud

func _mat(color: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(pos: Vector3, size: Vector3, color: Color, collide := false, parent: Node = null) -> Node3D:
	var node: Node3D
	if collide:
		node = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.name = "Collision"
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		node.add_child(shape)
	else:
		node = Node3D.new()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	node.add_child(mi)
	node.position = pos
	(parent if parent != null else self).add_child(node)
	return node

func sign3d(text: String, pos: Vector3, size := 40, color := Color("E7DFC9")) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = 8
	l.outline_modulate = NAVY
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	add_child(l)
	return l

## 低多邊形人物：身體加頭。回傳根節點，名牌是 Label3D。
func person(pos: Vector3, body_color: Color, label := "", height := 1.5) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	box(Vector3(0, height * 0.35, 0), Vector3(0.7, height * 0.7, 0.45), body_color, false, root)
	box(Vector3(0, height * 0.82, 0), Vector3(0.45, 0.45, 0.45), Color("E7C9A8"), false, root)
	if label != "":
		var l := Label3D.new()
		l.name = "Label"
		l.text = label
		l.position = Vector3(0, height + 0.5, 0)
		l.font_size = 40
		l.pixel_size = 0.01
		l.outline_size = 8
		l.outline_modulate = NAVY
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		root.add_child(l)
	return root

func interact(pos: Vector3, prompt: String, action: Callable, radius := 2.0, once := true) -> Node3D:
	var it := Node3D.new()
	it.set_script(INTERACTABLE)
	it.prompt = prompt
	it.radius = radius
	it.once = once
	it.action = action
	it.position = pos
	add_child(it)
	return it

func say(speaker: String, text: String, seconds := 2.8) -> void:
	story.hud.say(speaker, text, seconds)

func objective(text: String) -> void:
	story.hud.set_objective(text)

func shake(amount := 0.3) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_shake"):
		cam.add_shake(amount)

func spawn_enemy(pos: Vector3, ranged: bool, group: String, color: Color, hp := 40, awake_now := true, armor := false) -> Node3D:
	var e := ENEMY_SCENE.instantiate()
	e.awake = awake_now
	e.armor = armor
	e.camp = group
	e.max_hp = hp
	e.ranged = ranged
	e.base_color = color
	add_child(e)
	e.global_position = pos
	return e

func give_and_equip(type: String, rarity := 0) -> void:
	var item: Dictionary = jax.make_item(type, rarity)
	if jax.add_item(item):
		jax.toggle_equip(item["uid"])

func save_and_go(level_name: String) -> void:
	jax.save_progress(false)
	CHAPTER.level = level_name
	get_tree().reload_current_scene()

## 戶外關卡：天空、地面、看不見的邊界。half 是半長半寬。
func outdoor(sky: Color, ground: Color, half := Vector2(22, 16)) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("F4E9D6")
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	main.get_node("Floor/Mesh").visible = false
	box(Vector3(0, 0.01, 0), Vector3(half.x * 2.0, 0.02, half.y * 2.0), ground)
	for d in [Vector3(0, 2, -half.y), Vector3(0, 2, half.y), Vector3(-half.x, 2, 0), Vector3(half.x, 2, 0)]:
		var size := Vector3(half.x * 2.0 + 2.0, 4, 1) if d.x == 0.0 else Vector3(1, 4, half.y * 2.0 + 2.0)
		var wall := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		wall.add_child(shape)
		wall.position = d
		add_child(wall)

func portal(pos: Vector3, prompt: String, label: String, action: Callable) -> void:
	sign3d(label, pos + Vector3(0, 2.6, 0), 22, YELLOW)
	box(pos + Vector3(0, 0.03, 0), Vector3(2.4, 0.06, 1.2), YELLOW)
	interact(pos, prompt, action, 2.2, false)

func pickup_item(pos: Vector3, item: Dictionary) -> void:
	var p := Node3D.new()
	p.set_script(preload("res://game/scripts/pickup.gd"))
	p.kind = "item"
	p.item = item
	add_child(p)
	p.global_position = pos + Vector3(0, 0.5, 0)

func enemies_left(group: String) -> int:
	return get_tree().get_nodes_in_group(group).size()
