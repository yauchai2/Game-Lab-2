extends "res://game/scripts/levels/level_base.gd"
## 第一章開場：合租單位。拍醒電視、早餐教學、出門。
## 步驟順序：tv → fridge → note → rack → bench → cable → junk → 出門。

const STEPS := ["tv", "fridge", "note", "rack", "bench", "cable", "junk"]
const STEP_TEXT := {
	"tv": "拍醒電視（走近按 E）",
	"fridge": "看看冰箱有什麼吃",
	"note": "撿起房門縫的字條",
	"rack": "從工具架挑一件起始裝備",
	"bench": "到工作枱換一次零件（按 E，按 C 關閉）",
	"cable": "按空白鍵衝過地上的電線",
	"junk": "推開擋門的雜物",
}
const CABLE_X := 2.4

var tv_screen: Node3D
var junk_body: StaticBody3D
var note_it: Node3D
var rack_items: Array = []
var shock_cd := 0.0
var cable_side := -1

func _ready() -> void:
	_setup_refs()
	_environment()
	_build_room()
	_build_props()
	_build_logic()
	await get_tree().process_frame
	_start()

func _environment() -> void:
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

func _build_room() -> void:
	box(Vector3(0, 0.01, 0), Vector3(12.5, 0.02, 10.5), Color("B58E69"))
	# 牆：後牆、左牆、右牆；前面敞開給鏡頭，用看不見的牆擋住。
	box(Vector3(0, 2.0, -5.3), Vector3(13.1, 4.0, 0.6), Color("E7DFC9"), true)
	box(Vector3(-6.3, 2.0, 0), Vector3(0.6, 4.0, 10.6), Color("D9C9AE"), true)
	box(Vector3(6.3, 2.0, 0), Vector3(0.6, 4.0, 10.6), Color("D9C9AE"), true)
	var barrier := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(13, 4, 0.5)
	shape.shape = bs
	barrier.add_child(shape)
	barrier.position = Vector3(0, 2, 5.4)
	add_child(barrier)
	# 窗口：車燈偶爾掃過
	box(Vector3(-2.0, 2.4, -4.98), Vector3(2.0, 1.3, 0.05), Color("52B7F0"))
	box(Vector3(-2.0, 2.4, -4.95), Vector3(0.08, 1.3, 0.06), Color("292D3B"))
	# 掛燈
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 3.4, 0)
	lamp.light_color = Color("FFE2B0")
	lamp.light_energy = 1.2
	lamp.omni_range = 14.0
	add_child(lamp)

func _build_props() -> void:
	# 沙發與電視
	box(Vector3(-4, 0.4, -2.0), Vector3(3.0, 0.8, 1.2), SLATE, true)
	box(Vector3(-4, 1.0, -1.55), Vector3(3.0, 0.9, 0.3), Color("6F82A8"))
	box(Vector3(-4, 0.4, -4.7), Vector3(2.4, 0.8, 0.7), WOOD, true)
	box(Vector3(-4, 1.35, -4.7), Vector3(1.7, 1.0, 0.18), NAVY)
	tv_screen = box(Vector3(-4, 1.35, -4.6), Vector3(1.5, 0.82, 0.03), Color("14161F"))
	# 冰箱
	box(Vector3(-0.6, 1.0, -4.5), Vector3(1.0, 2.0, 0.9), CHALK, true)
	box(Vector3(-0.1, 1.3, -4.02), Vector3(0.06, 0.6, 0.06), NAVY)
	# 餐桌與半個三明治
	box(Vector3(1.4, 0.8, -2.4), Vector3(2.0, 0.1, 1.1), WOOD, true)
	box(Vector3(0.6, 0.4, -2.0), Vector3(0.12, 0.8, 0.12), NAVY)
	box(Vector3(2.2, 0.4, -2.8), Vector3(0.12, 0.8, 0.12), NAVY)
	box(Vector3(1.3, 0.9, -2.4), Vector3(0.45, 0.12, 0.3), Color("D6D573"))
	box(Vector3(1.3, 1.0, -2.4), Vector3(0.4, 0.06, 0.26), Color("75C7B0"))
	# 房門（室友）
	box(Vector3(2.8, 1.1, -4.95), Vector3(1.2, 2.2, 0.1), MAUVE)
	# 出門的門
	box(Vector3(6.0, 1.1, -0.4), Vector3(0.12, 2.2, 1.4), CORAL)
	sign3d("出口", Vector3(5.6, 2.9, -0.4), 24)
	# 電線
	box(Vector3(CABLE_X, 0.04, 0.3), Vector3(0.3, 0.06, 6.0), CORAL)
	# 擋門的雜物
	junk_body = box(Vector3(4.9, 0.5, -0.4), Vector3(1.3, 1.0, 1.3), Color("8C9871"), true)
	box(Vector3(0, 0.62, 0), Vector3(0.8, 0.3, 0.8), YELLOW, false, junk_body)
	# 工具架（左牆）
	box(Vector3(-6.0, 1.0, 1.5), Vector3(0.3, 2.0, 2.8), Color("6B5440"), true)
	# 工作枱
	box(Vector3(-3.2, 0.5, 3.4), Vector3(2.2, 1.0, 0.9), Color("7A8A9E"), true)
	box(Vector3(-3.6, 1.1, 3.4), Vector3(0.5, 0.2, 0.4), YELLOW)
	box(Vector3(-2.7, 1.12, 3.4), Vector3(0.3, 0.24, 0.3), CORAL)
	sign3d("工作枱", Vector3(-3.2, 2.0, 3.4), 24)
	# 室友（NPC）
	var skye := person(Vector3(1.6, 0, -3.4), Color("D6D573"), "Skye")
	var vee := person(Vector3(-0.3, 0, 2.2), MAUVE, "Vee")
	var niko := person(Vector3(-1.3, 0, 3.6), MOSS, "Niko", 1.8)
	for p in [skye, vee, niko]:
		var t := create_tween().set_loops()
		t.tween_property(p, "position:y", 0.08, 0.7)
		t.tween_property(p, "position:y", 0.0, 0.7)

func _build_logic() -> void:
	interact(Vector3(-4, 0, -3.5), "拍電視", _on_tv, 2.6)
	interact(Vector3(-0.6, 0, -3.3), "看冰箱", _on_fridge, 2.0).enabled = false
	note_it = interact(Vector3(2.8, 0, -4.0), "撿起字條", _on_note, 1.8)
	note_it.enabled = false
	var rack_defs := [
		{"label": "扳手", "type": "heavy", "z": 0.5, "line": "扳手：沉，敲下去有分量。（重踏）"},
		{"label": "改裝釘槍", "type": "burst", "z": 1.5, "line": "改裝釘槍：一下變兩下。（迴響震擊）"},
		{"label": "壞掉的音響模組", "type": "knock", "z": 2.5, "line": "音響模組：壞了，但響起來很大聲。（重拳）"},
	]
	for d in rack_defs:
		var item_box := box(Vector3(-5.7, 1.2, d["z"]), Vector3(0.4, 0.4, 0.4), YELLOW)
		var lbl := sign3d(d["label"], Vector3(-5.2, 2.0, d["z"]), 20)
		var it := interact(Vector3(-5.0, 0, d["z"]), "拿起" + d["label"], _on_rack.bind(d, item_box, lbl), 1.2)
		it.enabled = false
		rack_items.append({"it": it, "box": item_box, "label": lbl})
	interact(Vector3(-3.2, 0, 2.6), "工作枱", _on_bench, 2.0, false).enabled = false
	interact(Vector3(4.2, 0, -0.4), "推開雜物", _on_junk, 2.4).enabled = false
	interact(Vector3(5.2, 0, 0.9), "出門", _on_door, 2.6, false)

func _start() -> void:
	if CHAPTER.has("boss2_done"):
		_start_ending()
		return
	if CHAPTER.has("pawn_info"):
		_start_return()
		return
	# 主角還在睡：躺在沙發上，玩家先拍醒電視。
	jax.global_position = Vector3(-4, 1.15, -2.0)
	jax.model.rotation.x = -1.4
	jax.set_physics_process(false)
	jax.set_process_unhandled_input(false)
	say("", "（門外有人拍門）「醒了嗎？你的車又擋住別人做生意。」", 3.2)
	_update_objective()

## 結局：街坊把材料放在桌上，主角坐下來吃完三明治。
var eating := false
var finished := false

func _start_ending() -> void:
	jax.global_position = Vector3(0, 0.87, 3)
	tv_screen.get_node("Mesh").material_override = _mat(Color("75C7B0"), true)
	for it in get_tree().get_nodes_in_group("interactables"):
		it.enabled = false
	var guests := []
	if CHAPTER.has("cl03_fixed"):
		guests.append(["CL-03", MINT, "放下一包起司"])
	if CHAPTER.has("mechanic_gift"):
		guests.append(["修車師傅", Color("859AC1"), "放下一瓶醬"])
	if CHAPTER.has("roofer_gift"):
		guests.append(["天台街坊", YELLOW, "放下一把青菜"])
	if CHAPTER.flags.get("restore_choice", "self") == "both":
		guests.append(["鄰街街坊", Color("CC6657"), "放下一盒火腿"])
	for i in guests.size():
		person(Vector3(-2.5 + i * 1.8, 0, 0.8), guests[i][1], guests[i][0])
	interact(Vector3(1.4, 0, -1.4), "坐下，吃", _on_eat, 2.4)
	say("", "街坊把不同地方找來的材料放在桌上。", 3.2)
	for g in guests:
		say(g[0], "（%s）" % g[2], 1.8)
	objective("坐下，吃（走近桌子按 E）")

func _on_eat() -> void:
	eating = true
	jax.global_position = Vector3(1.4, 0.87, -1.0)
	jax.set_physics_process(false)
	jax.set_process_unhandled_input(false)
	say("", "你坐下來，咬了一口。三明治有點涼，餡料是對的。", 3.6)
	say("", "吃完了。", 1.8)
	objective("")
	get_tree().create_timer(6.0).timeout.connect(_ending_tv)

func _ending_tv() -> void:
	say("", "你把紀錄裝置接上舊電視。畫面是一張城市地圖：自己的街亮著，遠處有很多街區正一個一個熄滅。", 5.0)
	say("", "其中一個，是室友以前住的地方。房間安靜了一陣。", 3.6)
	say("Skye", "（指了指畫面，再指指牆上的鬧鐘：明天要早點起來。）", 3.6)
	get_tree().create_timer(12.0).timeout.connect(func() -> void:
		finished = true
		_story_hud().title("第一章完成", "第二章：去找其他被抹走的地方（未製作）", 6.0)
		objective("第一章完成。按 R 重新開始"))

func _unhandled_input(event: InputEvent) -> void:
	if finished and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		CHAPTER.reset()
		jax.save_progress(false)
		get_tree().reload_current_scene()

## 第一章中段後回家：拿頭盔，室友留字條，出門追運輸車。
func _start_return() -> void:
	jax.global_position = Vector3(0, 0.87, 3)
	tv_screen.get_node("Mesh").material_override = _mat(Color("75C7B0"), true)
	for it in get_tree().get_nodes_in_group("interactables"):
		it.enabled = it.prompt == "出門"
	var helmet := box(Vector3(1.3, 1.0, -2.4), Vector3(0.5, 0.35, 0.5), CORAL)
	interact(Vector3(1.3, 0, -1.2), "拿起頭盔", func() -> void:
		helmet.visible = false
		CHAPTER.set_flag("helmet")
		say("", "桌上的材料已經擺好了。一張字條壓在三明治旁邊。", 3.0)
		say("字條", "「還做不做？」", 2.2)
		say("", "（你戴上頭盔，指了指桌上的材料：回來再做。）", 3.2)
		objective("出門，追上運輸車"), 2.2)
	objective("拿起桌上的頭盔")

func _first_missing() -> String:
	for s in STEPS:
		if not CHAPTER.has(s):
			return s
	return ""

func _update_objective() -> void:
	var s := _first_missing()
	objective(STEP_TEXT[s] if s != "" else "出門，到樓下買午餐")
	# 依步驟開啟互動點
	for it in get_tree().get_nodes_in_group("interactables"):
		match it.prompt:
			"看冰箱":
				it.enabled = CHAPTER.has("tv") and not CHAPTER.has("fridge")
			"撿起字條":
				it.enabled = CHAPTER.has("fridge") and not CHAPTER.has("note")
			"工作枱":
				it.enabled = CHAPTER.has("rack")
			"推開雜物":
				it.enabled = CHAPTER.has("cable") and not CHAPTER.has("junk")
	for r in rack_items:
		if not r.get("taken", false):
			r["it"].enabled = CHAPTER.has("note") and not CHAPTER.has("rack")

func _done(step: String) -> void:
	CHAPTER.set_flag(step)
	_update_objective()

func _on_tv() -> void:
	tv_screen.get_node("Mesh").material_override = _mat(Color("75C7B0"), true)
	shake(0.35)
	jax._hit_stop(0.07)
	jax.set_physics_process(true)
	jax.set_process_unhandled_input(true)
	say("電視", "「本市所有問題，都可以透過登記解決。」", 3.0)
	say("", "左鍵移動，Q／右鍵拆場，空白鍵衝刺，C 打開工作枱。", 3.4)
	_done("tv")

func _on_fridge() -> void:
	say("", "冰箱裡有兩片麵包、一瓶不知道還能不能喝的牛奶。最重要的餡料，沒有了。", 3.6)
	note_it.position = Vector3(2.8, 0, -4.0)
	box(Vector3(2.8, 0.05, -4.3), Vector3(0.4, 0.02, 0.3), CHALK)
	_done("fridge")
	say("", "（房門縫塞出一張字條）", 2.0)

func _on_note() -> void:
	say("字條", "「吃光了。樓下買吧，順便幫我拿一件東西。」", 3.4)
	_done("note")

func _on_rack(d: Dictionary, item_box: Node3D, lbl: Node3D) -> void:
	give_and_equip(d["type"])
	say("", d["line"], 3.2)
	for r in rack_items:
		r["taken"] = true
		r["it"].enabled = false
		r["box"].visible = false
		r["label"].visible = false
	_done("rack")

func _on_bench() -> void:
	main.get_node("HUD").toggle_bench()
	if not CHAPTER.has("bench"):
		_done("bench")

func _on_junk() -> void:
	var t := create_tween()
	t.tween_property(junk_body, "position", Vector3(4.9, 0.5, 3.0), 0.5)
	junk_body.get_node("Collision").set_deferred("disabled", true)
	shake(0.2)
	say("", "雜物被推到一邊。", 1.8)
	_done("junk")

func _on_door() -> void:
	if CHAPTER.has("pawn_info"):
		if not CHAPTER.has("helmet"):
			say("", "先拿頭盔。", 1.8)
			return
		var loader := main.get_node("Street")
		if loader.LEVELS.has("chase"):
			save_and_go("chase")
		else:
			_story_hud().title("階段 2 完成", "階段 3：追車、章末頭目與結局仍在製作中", 4.0)
		return
	var s := _first_missing()
	if s != "":
		say("", "還不能出門。" + STEP_TEXT[s] + "。", 2.6)
		return
	say("", "（打開門，樓下的街道展開）", 1.6)
	get_tree().create_timer(1.4).timeout.connect(save_and_go.bind("street"))

func _physics_process(delta: float) -> void:
	if jax == null or CHAPTER.has("cable") or not CHAPTER.has("rack"):
		return
	shock_cd = maxf(shock_cd - delta, 0.0)
	var p: Vector3 = jax.global_position
	if absf(p.z - 0.3) > 3.0:
		return
	var side := 1 if p.x > CABLE_X else -1
	if absf(p.x - CABLE_X) < 0.45 and shock_cd <= 0.0:
		shock_cd = 1.0
		if jax.dash_left > 0.0 or jax.iframe_left > 0.0:
			say("", "衝過去了。", 1.4)
			_done("cable")
		else:
			jax.take_damage(4)
			shake(0.25)
			say("", "觸電！下次按空白鍵衝過去。", 2.0)
	if side > 0 and cable_side < 0 and absf(p.x - CABLE_X) >= 0.45:
		# 走到另一邊就算過關，不要讓玩家卡住
		say("", "電線被你踩斷了。", 1.6)
		_done("cable")
	cable_side = side
