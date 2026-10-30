extends Control
## 開局選角：左右兩張卡，點擊後進入街區。

const PROGRESS := preload("res://game/scripts/progress.gd")
const SFX := preload("res://game/scripts/sfx.gd")
const CHARACTERS := [
	{"id": "jax", "name": "Jax　傑克斯", "model": "res://assets/characters/jax.glb",
		"desc": "近身重擊，打碎一切\n拆場：身邊範圍震擊\n自動普攻：近戰\n生命較高"},
	{"id": "skye", "name": "Skye　絲凱", "model": "res://assets/characters/skye.glb",
		"desc": "遠程惡作劇，耍弄敵群\n惡作劇彈：投向滑鼠位置\n自動普攻：遠程射擊\n生命較低"},
]

var spinners: Array[Node3D] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("292D3B")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "選擇角色"
	title.add_theme_font_size_override("font_size", 20)
	title.position = Vector2(0, 14)
	title.size = Vector2(640, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	for i in CHARACTERS.size():
		_card(i, CHARACTERS[i])

func _card(i: int, c: Dictionary) -> void:
	var box := Vector2(250, 290)
	var origin := Vector2(55 + i * 280, 52)
	var frame := ColorRect.new()
	frame.color = Color("3A4054")
	frame.position = origin
	frame.size = box
	add_child(frame)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.position = origin + Vector2(25, 4)
	svc.size = Vector2(200, 150)
	add_child(svc)
	var vp := SubViewport.new()
	vp.size = Vector2i(200, 150)
	vp.transparent_bg = true
	vp.own_world_3d = true
	svc.add_child(vp)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.position = Vector3(0, 0.95, 3.2)
	cam.fov = 40
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	vp.add_child(env)
	var model: Node3D = load(c["model"]).instantiate()
	model.rotation.y = PI
	vp.add_child(model)
	spinners.append(model)
	var name_label := Label.new()
	name_label.text = c["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.position = origin + Vector2(0, 156)
	name_label.size = Vector2(box.x, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)
	var desc := Label.new()
	desc.text = c["desc"]
	desc.add_theme_font_size_override("font_size", 9)
	desc.position = origin + Vector2(14, 180)
	desc.size = Vector2(box.x - 28, 70)
	add_child(desc)
	var btn := Button.new()
	btn.text = "選擇"
	btn.position = origin + Vector2(75, 254)
	btn.size = Vector2(100, 26)
	btn.pressed.connect(_pick.bind(c["id"]))
	add_child(btn)

func _process(delta: float) -> void:
	for m in spinners:
		m.rotation.y += delta * 0.8

func _pick(id: String) -> void:
	PROGRESS.character = id
	PROGRESS.data = {}
	SFX.play(self, "ui_click")
	get_tree().change_scene_to_file("res://game/main.tscn")
