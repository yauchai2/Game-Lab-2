extends "res://game/scripts/levels/level_base.gd"
## 選角：四人合租單位，各自用自己的方式處理同一台壞掉的多士爐。按 1 至 4 選擇。

const PICKS := [
	{"key": KEY_1, "name": "Jax", "color": Color("CC6657"), "ok": true, "gesture": "Jax：拍兩下，再把發熱線接上護臂。重擊、蓄力、電擊。"},
	{"key": KEY_2, "name": "Vee", "color": Color("9B8ACC"), "ok": false, "gesture": "Vee：指尖點一下腕部介面，多士爐隔空啟動。範圍控制、干擾、連鎖。"},
	{"key": KEY_3, "name": "Skye", "color": Color("D6D573"), "ok": false, "gesture": "Skye：快速拆件，用彈簧彈出麵包，順手拋給別人。位移、連擊、投擲、槍械。"},
	{"key": KEY_4, "name": "Niko", "color": Color("8C9871"), "ok": false, "gesture": "Niko：放出一隻小機偶爬進去修理。裝置、召喚、陷阱。"},
]

func _ready() -> void:
	_setup_refs()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1C1F2B")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("F4E9D6")
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	main.get_node("Floor/Mesh").visible = false
	box(Vector3(0, 0.01, 0), Vector3(14, 0.02, 10), Color("B58E69"))
	box(Vector3(0, 2.0, -5.3), Vector3(14.6, 4.0, 0.6), Color("E7DFC9"), true)
	box(Vector3(0, 0.5, -1.5), Vector3(3.0, 1.0, 1.4), WOOD, true)
	var toaster := box(Vector3(0, 1.2, -1.5), Vector3(0.8, 0.4, 0.5), Color("7A8A9E"))
	sign3d("壞掉的多士爐", Vector3(0, 2.2, -1.5), 22)
	jax.global_position = Vector3(0, 0.87, 4.5)
	jax.model.visible = false
	jax.set_physics_process(false)
	jax.set_process_unhandled_input(false)
	for i in PICKS.size():
		var p: Dictionary = PICKS[i]
		var x := -4.5 + i * 3.0
		person(Vector3(x, 0, 1.0), p["color"], "%d　%s" % [i + 1, p["name"]])
		box(Vector3(x, 0.03, 1.0), Vector3(1.6, 0.06, 1.6), p["color"] if p["ok"] else Color("5C6478"))
		if not p["ok"]:
			sign3d("尚未開放", Vector3(x, 2.4, 1.0), 16, Color("859AC1"))
	await get_tree().process_frame
	_story_hud().title("誰今天下樓？", "按 1 至 4 選擇角色", 3.0)
	objective("選一個角色（目前只有 Jax 可玩）")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	for p in PICKS:
		if event.keycode == p["key"]:
			say("", p["gesture"], 3.6)
			if p["ok"]:
				get_tree().create_timer(2.4).timeout.connect(save_and_go.bind("home"))
			else:
				say("", "%s 的玩法仍在製作，請先選 Jax。" % p["name"], 2.6)
			return
