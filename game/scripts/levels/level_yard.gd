extends "res://game/scripts/levels/level_base.gd"
## 後巷維修場：找回三個通行零件，遇到第一批裝甲敵人，學習破防。旗標：part1、part2、part3、yard_done。

const PARTS := [
	{"flag": "part1", "pos": Vector3(-14, 0, -9), "camp": [Vector3(-13, 0, -7), 3, 0, 0]},
	{"flag": "part2", "pos": Vector3(13, 0, -11), "camp": [Vector3(12, 0, -8), 1, 1, 2]},
	{"flag": "part3", "pos": Vector3(-5, 0, 3), "camp": [Vector3(-3, 0, 6), 0, 1, 3]},
]
var armor_hint := false

func _ready() -> void:
	_setup_refs()
	outdoor(Color("3A4A66"), Color("4A4F5E"), Vector2(22, 16))
	_build_scrap()
	_build_parts()
	jax.global_position = Vector3(0, 0.87, 12)
	portal(Vector3(0, 0, 14.5), "返回街道", "回街", func() -> void: save_and_go("street"))
	await get_tree().process_frame
	say("", "起重機的影子晃過鐵皮牆。這裡的設備會自己動。", 3.4)
	_refresh()

func _build_scrap() -> void:
	var colors := [CORAL, MOSS, SLATE, YELLOW, MAUVE]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var pos := Vector3(rng.randf_range(-19, 19), 0.6, rng.randf_range(-13, 9))
		if pos.distance_to(Vector3(0, 0, 12)) < 6.0:
			continue
		box(pos, Vector3(rng.randf_range(2.5, 4.0), 1.2, rng.randf_range(1.5, 2.2)), colors[i % colors.size()], true)
	box(Vector3(-20.5, 5.0, -4), Vector3(1.0, 10.0, 1.0), NAVY)
	box(Vector3(-12.0, 9.5, -4), Vector3(16.0, 0.8, 0.8), NAVY)
	box(Vector3(0, 3.0, -15.5), Vector3(44, 6, 1), Color("6B5440"))
	sign3d("維修場　閒人免進", Vector3(0, 5.0, -14.5), 30, YELLOW)

func _build_parts() -> void:
	for i in PARTS.size():
		var p: Dictionary = PARTS[i]
		if not CHAPTER.has(p["flag"]):
			var b := box(p["pos"] + Vector3(0, 0.5, 0), Vector3(0.6, 0.6, 0.6), YELLOW)
			interact(p["pos"], "拾起通行零件", _on_part.bind(p["flag"], b), 1.8)
			var c: Array = p["camp"]
			var group := "yard_%d" % i
			for k in c[1]:
				spawn_enemy(c[0] + Vector3(k * 1.5 - 1.5, 0, 0), false, group, Color("8C9871"), 40, false)
			for k in c[2]:
				spawn_enemy(c[0] + Vector3(k * 1.5, 0, 2.0), true, group, Color("9B8ACC"), 28, false)
			for k in c[3]:
				spawn_enemy(c[0] + Vector3(k * 1.8 - 1.8, 0, -1.5), false, group, Color("5C6478"), 70, false, true)

func _on_part(flag: String, b: Node3D) -> void:
	b.visible = false
	CHAPTER.set_flag(flag)
	say("", "通行零件 %d／3。" % _parts_got(), 1.8)
	_refresh()

func _parts_got() -> int:
	var n := 0
	for p in PARTS:
		if CHAPTER.has(p["flag"]):
			n += 1
	return n

func _refresh() -> void:
	if _parts_got() >= 3:
		CHAPTER.set_flag("yard_done")
		objective("通行零件齊了，回街")
	else:
		objective("找回被收走的通行零件（%d／3）" % _parts_got())

func _process(_d: float) -> void:
	if armor_hint or jax == null:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.armor and e.awake:
			armor_hint = true
			say("", "裝甲保全機：普通攻擊幾乎無效。用拆場（Q／右鍵）破防。", 4.0)
			return
