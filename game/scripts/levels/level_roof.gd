extends "res://game/scripts/levels/level_base.gd"
## 天台接駁區：向街坊借天線。修理、賠償、走危險的路三選一。旗標：antenna、roof_done、roof_choice。

var wave_started := false
var owner_npc: Node3D

func _ready() -> void:
	_setup_refs()
	outdoor(Color("52B7F0"), Color("C9CDBF"), Vector2(20, 14))
	_build_roof()
	jax.global_position = Vector3(0, 0.87, 11)
	portal(Vector3(0, 0, 12.5), "返回街道", "回街", func() -> void: save_and_go("street"))
	await get_tree().process_frame
	say("", "天台比街上明亮。晾著衣服的繩子之間，有人養了盆栽。", 3.2)
	_refresh()

func _build_roof() -> void:
	for x in [-14, -9, 9, 14]:
		box(Vector3(x, 1.0, -2), Vector3(0.1, 2.0, 0.1), NAVY)
	box(Vector3(-11.5, 1.8, -2), Vector3(5.5, 0.05, 0.05), CHALK)
	box(Vector3(11.5, 1.8, -2), Vector3(5.5, 0.05, 0.05), CHALK)
	for p in [Vector3(-6, 0, 6), Vector3(7, 0, 5), Vector3(-15, 0, 8)]:
		box(p + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9), Color("B58E69"), true)
		box(p + Vector3(0, 1.0, 0), Vector3(0.7, 0.6, 0.7), MINT)
	box(Vector3(0, 1.0, -8), Vector3(5, 2.0, 2.5), Color("D9C9AE"), true)
	box(Vector3(0, 3.6, -8), Vector3(0.15, 3.2, 0.15), NAVY)
	box(Vector3(0, 5.2, -8), Vector3(2.4, 0.15, 0.15), NAVY)
	sign3d("天線（壞了）", Vector3(0, 6.2, -8), 24, CORAL)
	owner_npc = person(Vector3(3.5, 0, -5), Color("D6D573"), "街坊（阿叔）")
	interact(Vector3(3.5, 0, -3.8), "和阿叔談天線", _on_talk, 2.2, false)
	# 兩名遠程敵人守在天台中央
	for x in [-8, 8]:
		spawn_enemy(Vector3(x, 0, 0), true, "roof_guard", Color("9B8ACC"), 28, false)

func _on_talk() -> void:
	if CHAPTER.has("antenna"):
		say("阿叔", "拿去用吧。別再把車停在我的天線底下。", 2.8)
		return
	say("阿叔", "你早上移車，撞壞了我的天線。我憑什麼借你？", 3.2)
	if not CHAPTER.flags.has("roof_choices"):
		CHAPTER.flags["roof_choices"] = true
		_show_choices()

func _show_choices() -> void:
	interact(Vector3(-0.8, 0, -6.4), "修理天線", _on_fix, 1.6)
	interact(Vector3(0.8, 0, -6.4), "賠償（2 單據）", _on_pay, 1.6, false)
	interact(Vector3(2.4, 0, -6.4), "走窄樑拿天線（較危險）", _on_danger, 1.6)
	say("", "三種辦法：修理它、賠錢，或者直接走過窄樑去拿。", 3.4)

func _finish(how: String, text: String) -> void:
	CHAPTER.set_flag("antenna")
	CHAPTER.set_flag("roof_done")
	CHAPTER.flags["roof_choice"] = how
	say("", text, 3.2)
	_refresh()

func _on_fix() -> void:
	_disable_choices()
	_finish("fix", "你蹲下去接回斷線，阿叔在旁邊挑剔。天線能用了。")

func _on_pay() -> void:
	if jax.receipts < 2:
		say("", "單據不足。", 1.6)
		return
	jax.receipts -= 2
	_disable_choices()
	_finish("pay", "你付了兩張單據。阿叔數了兩遍，把天線遞過來。")

func _on_danger() -> void:
	_disable_choices()
	wave_started = true
	say("", "窄樑那邊有人守著，不好走。", 2.4)
	for x in [-3, -1, 1, 3]:
		spawn_enemy(Vector3(x * 2.0, 0, -11), true, "roof_wave", Color("9B8ACC"), 28)

func _disable_choices() -> void:
	for it in get_tree().get_nodes_in_group("interactables"):
		if it.prompt in ["修理天線", "賠償（2 單據）", "走窄樑拿天線（較危險）"]:
			it.enabled = false

func _process(_d: float) -> void:
	if wave_started and not CHAPTER.has("antenna") and enemies_left("roof_wave") == 0 and Engine.get_process_frames() > 30:
		wave_started = false
		_finish("danger", "你踩著窄樑，把天線從固定座上拆了下來。")

func _refresh() -> void:
	if CHAPTER.has("antenna"):
		objective("已取得天線，回街")
	else:
		objective("向街坊借天線（走近按 G）")
