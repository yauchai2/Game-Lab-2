extends "res://game/scripts/levels/level_base.gd"
## 第一章：第一條街。買午餐、黑西裝人上門、雜貨店首戰、掉落核准模組。
## 旗標：arrived、bought、ambush、ambush_done、cl03_fixed、module_got、module_equipped、p1_done。

const STREET := preload("res://game/scripts/street.gd")
const PICKUP := preload("res://game/scripts/pickup.gd")

const START := Vector3(17, 0.87, 11)
const SHOP := Vector3(18.5, 0, 2.0)

var cl03: Node3D
var cl03_it: Node3D
var props: Dictionary = {}
var last_kill := Vector3(10, 0, 5)

func _ready() -> void:
	_setup_refs()
	var base := Node3D.new()
	base.set_script(STREET)
	add_child(base)
	_build_storefronts()
	_build_shop()
	_build_people()
	_build_exit()
	jax.global_position = START
	await get_tree().process_frame
	_resume()

func _build_storefronts() -> void:
	sign3d("合租單位", Vector3(20.2, 3.8, 11.0), 26)
	box(Vector3(20.85, 1.1, 11.0), Vector3(0.12, 2.2, 1.4), CORAL)
	sign3d("Bo 商店　24H", Vector3(20.0, 3.4, 2.0), 28, YELLOW)
	sign3d("當舖", Vector3(20.2, 3.4, -9.0), 26)
	sign3d("修車檔", Vector3(20.2, 3.4, -15.0), 26)
	sign3d("自助洗衣", Vector3(20.2, 3.4, -4.0), 26)

func _build_shop() -> void:
	# 店員機械人與櫃檯
	cl03 = person(SHOP, MINT, "CL-03", 1.6)
	box(Vector3(0, 1.8, 0), Vector3(0.08, 0.5, 0.08), NAVY, false, cl03)
	box(Vector3(19.7, 0.6, 2.0), Vector3(1.0, 1.2, 2.6), WOOD, true)
	cl03_it = interact(SHOP + Vector3(-0.8, 0, 0), "買午餐材料", _on_buy, 2.4)
	# 雜貨店門口的場景道具：戰鬥時才可互動（額外選擇，基本打法同樣可靠）
	var shelf := box(Vector3(20.4, 1.0, 0.0), Vector3(0.7, 2.0, 1.6), Color("6B5440"), true)
	box(Vector3(-0.1, 0.4, 0), Vector3(0.4, 0.3, 1.2), CORAL, false, shelf)
	box(Vector3(-0.1, 1.2, 0), Vector3(0.4, 0.3, 1.2), YELLOW, false, shelf)
	var basket := box(Vector3(17.0, 0.3, 3.8), Vector3(0.7, 0.6, 0.7), SLATE, true)
	var lamp := box(Vector3(16.2, 1.2, 0.6), Vector3(0.25, 2.4, 0.25), NAVY, true)
	var lamp_head := box(Vector3(0, 1.3, 0), Vector3(1.2, 0.5, 0.2), YELLOW, false, lamp)
	props = {
		"shelf": interact(Vector3(19.4, 0, 0.0), "推倒貨架", _on_shelf.bind(shelf), 1.8),
		"basket": interact(Vector3(17.0, 0, 3.0), "踢購物籃", _on_basket.bind(basket), 1.8),
		"lamp": interact(Vector3(16.2, 0, 1.4), "打壞燈牌", _on_lamp.bind(lamp_head), 1.8),
	}
	for p in props.values():
		p.enabled = false

func _build_people() -> void:
	var neighbours := [
		{"pos": Vector3(13, 0, 7), "color": MOSS, "label": "街坊", "lines": ["「早啊。你的車又擋住別人做生意了。」", "「今天網路特別慢，說是在『更新資料』。」"]},
		{"pos": Vector3(8, 0, -2), "color": MAUVE, "label": "街坊", "lines": ["「聽說昨晚有人被登記系統刪掉了名字。」", "「別人問起，我什麼都沒說。」"]},
	]
	for n in neighbours:
		person(n["pos"], n["color"], n["label"])
		var idx := [0]
		interact(n["pos"] + Vector3(-1.0, 0, 0), "聽街坊說話", func() -> void:
			say(n["label"], n["lines"][idx[0] % n["lines"].size()])
			idx[0] += 1, 2.0, false)

func _build_exit() -> void:
	sign3d("舊街區（練習場）", Vector3(0, 3.0, -19.5), 24)
	interact(Vector3(0, 0, -17.5), "前往舊街區（自由練習）", func() -> void: save_and_go("arena"), 2.5, false)

func _resume() -> void:
	if not CHAPTER.has("arrived"):
		CHAPTER.set_flag("arrived")
		_story_hud().title("街外有事", "第一章：吃完再說")
	_refresh_state()
	if CHAPTER.has("ambush") and not CHAPTER.has("ambush_done"):
		# 重開後繼續被追
		_spawn_ambush(false)

func _refresh_state() -> void:
	if not CHAPTER.has("bought"):
		objective("到 Bo 商店買午餐材料（走近按 E）")
	elif not CHAPTER.has("ambush_done"):
		objective("擊退黑西裝人（可踢購物籃、推倒貨架、打壞燈牌）")
	elif not CHAPTER.has("module_got"):
		objective("拾起掉落的核准模組")
	elif not CHAPTER.has("module_equipped"):
		objective("按 C 打開工作枱，裝上核准模組")
	elif not CHAPTER.has("cl03_fixed"):
		objective("扶起並重新接上店員機械人（CL-03）")
	else:
		objective("第一章仍在製作：可去舊街區自由練習")
	cl03_it.enabled = not CHAPTER.has("bought") and not CHAPTER.has("ambush")

func _on_buy() -> void:
	say("CL-03", "歡迎光臨。今日特價：全部。已記賬。", 2.6)
	say("", "餡料、起司、生菜，都買到了。", 2.2)
	CHAPTER.set_flag("bought")
	_refresh_state()
	get_tree().create_timer(3.5).timeout.connect(_start_ambush)

func _start_ambush() -> void:
	if CHAPTER.has("ambush"):
		return
	CHAPTER.set_flag("ambush")
	_spawn_ambush(true)

func _spawn_ambush(with_lines: bool) -> void:
	var grabber := spawn_enemy(Vector3(9, 0, 5), false, "ambush", Color("292D3B"), 55, not with_lines)
	var scanner := spawn_enemy(Vector3(11, 0, 8), true, "ambush", Color("4A4E69"), 30, not with_lines)
	if not with_lines:
		_arm_props()
		_refresh_state()
		return
	say("黑西裝", "住戶資料更新。你的地址已被撤銷。", 3.0)
	say("黑西裝", "系統顯示，您沒睡過。", 2.6)
	say("", "（你停下腳步，抬頭望向遠處自己的窗口。）", 2.8)
	get_tree().create_timer(8.0).timeout.connect(func() -> void:
		if is_instance_valid(grabber):
			grabber.wake()
		cl03.get_node("Label").text = "CL-03（斷電）"
		say("黑西裝", "店員，請配合。", 1.8)
		_arm_props()
		_refresh_state())

func _arm_props() -> void:
	for p in props.values():
		p.enabled = true

func _near_enemies(pos: Vector3, radius: float) -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(func(e: Node3D) -> bool: return e.global_position.distance_to(pos) <= radius)

func _on_shelf(shelf: Node3D) -> void:
	var t := create_tween()
	t.tween_property(shelf, "rotation:z", 1.4, 0.35)
	shake(0.3)
	for e in _near_enemies(Vector3(18.0, 0, 0.0), 3.5):
		e.take_damage(25, Vector3(20.4, 0, 0.0), 8.0)
	say("", "貨架倒了，水果滾了一地。", 1.8)

func _on_basket(basket: Node3D) -> void:
	var t := create_tween()
	t.tween_property(basket, "position", basket.position + Vector3(-3.0, 0, -1.5), 0.3)
	for e in _near_enemies(basket.position + Vector3(-3.0, 0, -1.5), 3.0):
		e.take_damage(18, basket.position, 10.0)
	say("", "購物籃飛出去了。", 1.6)

func _on_lamp(lamp_head: Node3D) -> void:
	lamp_head.get_node("Mesh").material_override = _mat(CORAL, true)
	shake(0.25)
	for e in _near_enemies(Vector3(16.2, 0, 0.6), 4.5):
		e.take_damage(15, Vector3(16.2, 0, 0.6), 4.0)
		e.cooldown = 2.0
	say("", "燈牌爆出火花，附近的人僵住了。", 1.8)

func _process(_delta: float) -> void:
	if jax == null:
		return
	if CHAPTER.has("ambush") and not CHAPTER.has("ambush_done"):
		var alive := get_tree().get_nodes_in_group("ambush")
		if alive.is_empty() and get_tree().get_nodes_in_group("enemies").is_empty():
			_on_ambush_done()
		else:
			for e in alive:
				last_kill = e.global_position
	elif CHAPTER.has("ambush_done") and not CHAPTER.has("module_got") and _has_module():
		CHAPTER.set_flag("module_got")
		say("", "核准模組：本來用來鎖定你。現在，拆走管住人的工具，改成自己的武器。", 4.2)
		_refresh_state()
	elif CHAPTER.has("module_got") and not CHAPTER.has("module_equipped") and _module_equipped():
		CHAPTER.set_flag("module_equipped")
		_story_hud().title("核准模組已裝上", "拆場會輕微追向最近的敵人")
		_refresh_state()
		_maybe_finish()

func _has_module() -> bool:
	return _module_equipped() or jax.inventory.any(func(it: Dictionary) -> bool: return it["type"] in ["track", "link", "overload"])

func _module_equipped() -> bool:
	for t in ["track", "link", "overload"]:
		if jax.item_in_slots(t) != null:
			return true
	return false

func _on_ambush_done() -> void:
	CHAPTER.set_flag("ambush_done")
	var p := Node3D.new()
	p.set_script(PICKUP)
	p.kind = "item"
	p.item = jax.make_item("track", 1)
	add_child(p)
	p.global_position = last_kill + Vector3(0, 0.5, 0)
	cl03_it.prompt = "重新接上電源"
	cl03_it.action = _on_fix_cl03
	cl03_it.enabled = true
	_refresh_state()

func _on_fix_cl03() -> void:
	cl03.get_node("Label").text = "CL-03"
	say("", "你把電源重新插上。", 1.8)
	say("CL-03", "謝謝。你剛才壓爛了那箱水果，照價計算。", 3.2)
	CHAPTER.set_flag("cl03_fixed")
	_refresh_state()
	_maybe_finish()

func _maybe_finish() -> void:
	if CHAPTER.has("module_equipped") and CHAPTER.has("cl03_fixed") and not CHAPTER.has("p1_done"):
		CHAPTER.set_flag("p1_done")
		get_tree().create_timer(2.5).timeout.connect(func() -> void:
			_story_hud().title("階段 1 完成", "第一章仍在製作中：下一段是後巷維修場", 3.5)
			_refresh_state())
