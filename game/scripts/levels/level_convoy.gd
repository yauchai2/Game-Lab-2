extends "res://game/scripts/levels/level_base.gd"
## 章末頭目：運輸平台上的 TK-060「領帶」。旗標：boss2_start、boss2_done。

const TIE := preload("res://game/scripts/tie_boss.gd")
const BOSS_SCENE := preload("res://game/boss.tscn")

var boss: Node3D = null
var crates: Array = []
var stripes: Array = []
var reshuffle_t := 0.0

func _ready() -> void:
	_setup_refs()
	outdoor(Color("4A3F6B"), Color("5C6478"), Vector2(9, 18))
	# 兩側是往後飛逝的高架橋：用移動的條紋表現速度
	for i in 14:
		for s in [-1, 1]:
			var b := box(Vector3(s * 12.5, 0.5, -18 + i * 3.0), Vector3(1.0, 1.0, 1.6), [Color("CC6657"), Color("D6D573"), Color("859AC1")][i % 3])
			stripes.append(b)
	for x in [-8.4, 8.4]:
		box(Vector3(x, 0.6, 0), Vector3(0.3, 1.2, 36), NAVY, true)
	for p in [Vector3(-5, 0, 6), Vector3(5, 0, 6), Vector3(0, 0, 11)]:
		var c := box(p + Vector3(0, 0.7, 0), Vector3(2.2, 1.4, 2.2), Color("8C9871"), true)
		crates.append(c)
	jax.global_position = Vector3(0, 0.87, 14)
	await get_tree().process_frame
	_story_hud().title("TK-060「領帶」", "運輸平台", 2.0)
	objective("擊敗 TK-060「領帶」")
	get_tree().create_timer(2.4).timeout.connect(_spawn_boss)

func _spawn_boss() -> void:
	if boss != null:
		return
	CHAPTER.set_flag("boss2_start")
	boss = BOSS_SCENE.instantiate()
	boss.set_script(TIE)
	boss.awake = false
	if CHAPTER.flags.get("restore_choice", "self") == "both":
		boss.hp_scale = 1.15
	add_child(boss)
	boss.global_position = Vector3(0, 0.05, -10)
	main.boss = boss
	boss.defeated.connect(_on_defeated)
	boss.phase_changed.connect(_on_phase)
	boss.confused_changed.connect(_on_confused)
	say("TK-060「領帶」", "（拉直領帶）本次作業流程如下：請配合。", 3.2)
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if is_instance_valid(boss):
			boss.wake())

func _on_phase(p: int) -> void:
	if p == 2:
		say("TK-060「領帶」", "進入現場重組。", 2.4)
		_reshuffle()
	else:
		say("", "街坊傳來大量互相矛盾的舊紀錄：同一個地址十幾個名字、樓梯被登記成房間。", 4.0)

func _on_confused(on: bool) -> void:
	if on:
		say("TK-060「領帶」", "……無法分類。", 2.2)
		_story_hud().set_prompt("")
		objective("他露出破綻，全力攻擊！")
	else:
		objective("擊敗 TK-060「領帶」")

func _reshuffle() -> void:
	var spots := [Vector3(-5, 0.7, -4), Vector3(5, 0.7, -4), Vector3(0, 0.7, 0), Vector3(-6, 0.7, 10), Vector3(6, 0.7, 2)]
	spots.shuffle()
	for i in crates.size():
		create_tween().tween_property(crates[i], "position", spots[i], 1.2)
	shake(0.3)

func _process(delta: float) -> void:
	for b in stripes:
		b.position.z += 14.0 * delta
		if b.position.z > 20.0:
			b.position.z -= 42.0
	if boss != null and is_instance_valid(boss) and boss.phase == 2:
		reshuffle_t += delta
		if reshuffle_t > 9.0:
			reshuffle_t = 0.0
			_reshuffle()

func _on_defeated() -> void:
	main.boss = null
	# 最後一擊：鏡頭短暫誇張透視，再回到正常視角
	var cam := get_viewport().get_camera_3d()
	var t := create_tween()
	t.tween_property(cam, "fov", 100.0, 0.15)
	t.tween_property(cam, "fov", 60.0, 0.5)
	main.get_node("HUD").lines.burst(1.5)
	shake(0.5)
	say("TK-060「領帶」", "……已記錄。", 2.2)
	say("", "運輸車的後門打開了。住戶紀錄安靜地躺在箱子裡。", 3.4)
	CHAPTER.set_flag("boss2_done")
	objective("")
	get_tree().create_timer(4.5).timeout.connect(func() -> void:
		_story_hud().title("紀錄拿回來了", "回到自己的街", 2.2)
		get_tree().create_timer(2.4).timeout.connect(save_and_go.bind("home")))
