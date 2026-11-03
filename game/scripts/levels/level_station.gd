extends "res://game/scripts/levels/level_base.gd"
## 高架橋下管理站：Ada、讀取設備、修復範圍的選擇、頭目 TK-075「收據」。
## 旗標：reader、restore_choice（self／both）、boss1_start、boss1_done。

const RECEIPT := preload("res://game/scripts/receipt_boss.gd")
const BOSS_SCENE := preload("res://game/boss.tscn")

var boss: Node3D = null
var ada: Node3D

func _ready() -> void:
	_setup_refs()
	outdoor(Color("2E3445"), Color("5C6478"), Vector2(20, 16))
	_build_station()
	jax.global_position = Vector3(0, 0.87, 12)
	portal(Vector3(0, 0, 14.5), "返回街道", "回街", func() -> void: save_and_go("street"))
	await get_tree().process_frame
	say("Ada", "這條線不能亂接，隔壁那條可以，我寫下來了。", 3.0)
	_refresh()
	if CHAPTER.has("boss1_start") and not CHAPTER.has("boss1_done"):
		_spawn_boss()

func _build_station() -> void:
	for x in [-16, -8, 8, 16]:
		box(Vector3(x, 4.0, -12), Vector3(1.2, 8.0, 1.2), Color("6B5440"), true)
	box(Vector3(0, 8.4, -12), Vector3(36, 1.2, 4), Color("6B5440"))
	sign3d("管理站", Vector3(0, 6.0, -10), 30, YELLOW)
	box(Vector3(-4, 0.8, -7), Vector3(3.0, 1.6, 1.2), SLATE, true)
	box(Vector3(-4, 1.8, -7), Vector3(1.4, 0.5, 0.2), MINT)
	sign3d("讀取設備", Vector3(-4, 3.0, -7), 22)
	ada = person(Vector3(-12, 0, 6), MINT, "Ada")
	interact(Vector3(-11, 0, 6), "和 Ada 談話", _on_ada, 2.2, false)
	interact(Vector3(-4, 0, -5.4), "接上讀取設備", _on_reader, 2.2)
	for x in [-6, 6]:
		spawn_enemy(Vector3(x, 0, -2), false, "station_guard", Color("4A4E69"), 40, false)

func _on_ada() -> void:
	if CHAPTER.has("boss1_done"):
		say("Ada", "紀錄正由運輸車送走。回街找當舖老闆，他知道車隊的路線。", 3.4)
	elif not (CHAPTER.has("yard_done") and CHAPTER.has("roof_done")):
		say("Ada", "要讀取，需要通行零件和一根能用的天線。兩樣都沒湊齊。", 3.2)
	else:
		say("Ada", "零件和天線都有了。接上讀取設備吧。", 2.8)

func _on_reader() -> void:
	if not (CHAPTER.has("yard_done") and CHAPTER.has("roof_done")):
		say("", "設備沒有反應。還缺通行零件或天線。", 2.6)
		CHAPTER.flags.erase("reader")
		for it in get_tree().get_nodes_in_group("interactables"):
			if it.prompt == "接上讀取設備":
				it.enabled = true
		return
	CHAPTER.set_flag("reader")
	say("讀取設備", "原始住戶紀錄：已被移出。目的地：行政運輸車。", 3.4)
	say("", "至少可以先修復一部分。要修復多少？", 2.8)
	interact(Vector3(-5.5, 0, -5.4), "只修復自己的街", _on_choice.bind("self"), 1.6)
	interact(Vector3(-2.5, 0, -5.4), "順手修復鄰街", _on_choice.bind("both"), 1.6)

func _on_choice(which: String) -> void:
	for it in get_tree().get_nodes_in_group("interactables"):
		if it.prompt in ["只修復自己的街", "順手修復鄰街"]:
			it.enabled = false
	CHAPTER.flags["restore_choice"] = which
	say("", "已修復自己的街。" if which == "self" else "已修復自己的街，順手連鄰街一併修復。", 3.0)
	CHAPTER.set_flag("boss1_start")
	get_tree().create_timer(2.5).timeout.connect(_spawn_boss)

func _spawn_boss() -> void:
	if boss != null:
		return
	boss = BOSS_SCENE.instantiate()
	boss.set_script(RECEIPT)
	boss.awake = false
	add_child(boss)
	boss.global_position = Vector3(0, 0.05, -8)
	main.boss = boss
	boss.defeated.connect(_on_boss_defeated)
	boss.phase_changed.connect(_on_phase)
	say("TK-075「收據」", "收到，已記錄。這份紀錄，請交還。不交的話，我們會很有禮貌地處理你。", 4.0)
	objective("擊敗 TK-075「收據」（打爆蓋印機可削弱他）")
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(boss):
			boss.wake())

func _on_phase(p: int) -> void:
	if p == 2:
		say("", "他叫來兩名打工仔，旁邊多了一台蓋印機。打爆蓋印機。", 3.4)
	else:
		say("TK-075「收據」", "蓋印機已損壞。改用其他方式處理。", 3.0)

func _on_boss_defeated() -> void:
	CHAPTER.set_flag("boss1_done")
	main.boss = null
	say("TK-075「收據」", "已記錄。", 1.8)
	say("", "他的機器吐出一張拖到地上的收據。上面只有一行：待處理物件：整條街。", 4.2)
	say("TK-075「收據」", "這是客戶意見表。下次再見。", 3.0)
	if is_instance_valid(boss):
		var t := create_tween()
		t.tween_interval(3.0)
		t.tween_property(boss, "position:y", -6.0, 0.8)
	_refresh()

func _refresh() -> void:
	if CHAPTER.has("boss1_done"):
		objective("回街，向當舖老闆問運輸車的路線")
	elif CHAPTER.has("boss1_start"):
		objective("擊敗 TK-075「收據」")
	elif CHAPTER.has("reader"):
		objective("選擇修復的範圍")
	else:
		objective("接上讀取設備（需要通行零件與天線）")
