extends CanvasLayer
## 第一章流程：開場字幕 → 與 Bo 交談 → 清理據點 → 擊敗頭目「收據」→ 回商店結算 → 章節完結。
## 同時負責目標提示、教學提示、NPC 與對話框。文字一律書面語，保持簡短。

const PROGRESS := preload("res://game/scripts/progress.gd")
const SFX := preload("res://game/scripts/sfx.gd")

const INTRO := [
	"疊域。高架橋下，橋底街。",
	"一張取消得太遲的回收單，\n一箱沒有型號的卡匣。",
	"今天的工作：把箱子搬出去。",
]
const TALK_LINES := [
	["Bo", "回收的箱子在後面。冰箱不是，還是冷的。"],
	["Ren", "我的單子上有寫，只是寫得不清楚。"],
	["Bo", "路上的機器都不對勁。清完再來找我。"],
]
const RETURN_LINES := [
	["Bo", "回來了。箱子裡有一批貨，店家還在用。"],
	["Ren", "單子上寫的是整件回收。"],
]
const RESULT_RETURN := [
	["Bo", "……也好。工作枱的零件，我再想辦法。"],
	["Ren", "已記錄。這是你的報酬。"],
]
const RESULT_KEEP := [
	["Bo", "工作枱保住了。他們還會再來的。"],
	["Ren", "我什麼都沒看見。報酬先給你一部分。"],
]
const ADA_LINE := ["Ada", "這條線不能亂接，隔壁那條可以，我寫下來了。"]
const BOSS_WAKE := "TK-075：「收到，已記錄。這箱東西，請交還。」"
const BOSS_DOWN := "TK-075：「已記錄。下次再見。」"

const BO_POS := Vector3(4, 0, 14)
const REN_POS := Vector3(2, 0, 15)
const TALK_RANGE := 2.6

var stage := "intro"
var main: Node
var jax: Node
var busy := false
var npcs: Array[Dictionary] = []

var objective := Label.new()
var hint := Label.new()
var prompt := Label.new()
var caption := Label.new()
var caption_timer := 0.0
var overlay := Control.new()
var dialog_back := ColorRect.new()
var dialog_name := Label.new()
var dialog_text := Label.new()
var dialog_lines: Array = []
var dialog_done: Callable
var card_label := Label.new()
var card_lines: Array = []
var card_done: Callable
var choice_box := Control.new()
var end_box := Control.new()

var start_pos := Vector3.ZERO
var moved := false
var skill_used := false
var dashed := false
var bench_opened := false
var boss_woke := false
var boss_down_shown := false
var camps_saved := 0
var show_hints := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	main = get_parent()
	jax = main.get_node("Jax")
	start_pos = jax.global_position
	show_hints = PROGRESS.data.is_empty()
	_make_npc("Bo", BO_POS, Color("D6D573"))
	_make_npc("Ren", REN_POS, Color("9FB6E8"))
	_build_ui()
	jax.skill_cast.connect(func(_a: String, _b: String) -> void: skill_used = true)
	jax.dashed.connect(func() -> void: dashed = true)
	if PROGRESS.intro_seen:
		stage = "talk" if not PROGRESS.talked else "clear"
	else:
		_start_cards(INTRO, func() -> void:
			PROGRESS.intro_seen = true
			stage = "talk")

# ---------- 建立 ----------

func _make_npc(npc_name: String, pos: Vector3, color: Color) -> void:
	var n := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	capsule.material = mat
	body.mesh = capsule
	body.position.y = 0.75
	n.add_child(body)
	var tag := Label3D.new()
	tag.text = npc_name
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.pixel_size = 0.012
	tag.font_size = 48
	tag.outline_size = 8
	tag.position.y = 2.0
	tag.no_depth_test = true
	n.add_child(tag)
	main.add_child.call_deferred(n)
	n.set_deferred("global_position", pos)
	npcs.append({"name": npc_name, "pos": pos})

func _style_label(l: Label, font_px: int, color := Color("E7DFC9")) -> void:
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("20232E"))
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_ui() -> void:
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	for l in [objective, hint, prompt, caption]:
		l.size = Vector2(640, 16)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(l)
	objective.position = Vector2(0, 4)
	_style_label(objective, 10, Color("75C7B0"))
	hint.position = Vector2(0, 302)
	_style_label(hint, 10, Color("D6D573"))
	prompt.position = Vector2(0, 280)
	_style_label(prompt, 10)
	caption.position = Vector2(0, 52)
	_style_label(caption, 12, Color("CC6657"))
	dialog_back.color = Color(0.1, 0.11, 0.15, 0.92)
	dialog_back.position = Vector2(60, 246)
	dialog_back.size = Vector2(520, 70)
	dialog_back.visible = false
	overlay.add_child(dialog_back)
	dialog_name.position = Vector2(10, 4)
	dialog_name.add_theme_font_size_override("font_size", 11)
	dialog_name.add_theme_color_override("font_color", Color("D6D573"))
	dialog_back.add_child(dialog_name)
	dialog_text.position = Vector2(10, 22)
	dialog_text.size = Vector2(500, 40)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	dialog_text.add_theme_font_size_override("font_size", 11)
	dialog_back.add_child(dialog_text)
	var more := Label.new()
	more.text = "［E］繼續"
	more.position = Vector2(450, 52)
	more.add_theme_font_size_override("font_size", 8)
	more.add_theme_color_override("font_color", Color("9AA3AD"))
	dialog_back.add_child(more)
	card_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_label.add_theme_font_size_override("font_size", 16)
	card_label.visible = false
	var card_bg := ColorRect.new()
	card_bg.color = Color("14161D")
	card_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_bg.name = "CardBg"
	card_bg.visible = false
	overlay.add_child(card_bg)
	overlay.add_child(card_label)
	choice_box.visible = false
	overlay.add_child(choice_box)
	end_box.visible = false
	overlay.add_child(end_box)

# ---------- 字幕卡 ----------

func _start_cards(lines: Array, on_done: Callable) -> void:
	card_lines = lines.duplicate()
	card_done = on_done
	busy = true
	get_tree().paused = true
	overlay.get_node("CardBg").visible = true
	card_label.visible = true
	_next_card()

func _next_card() -> void:
	if card_lines.is_empty():
		overlay.get_node("CardBg").visible = false
		card_label.visible = false
		busy = false
		get_tree().paused = false
		card_done.call()
		return
	card_label.text = card_lines.pop_front() + "\n\n［E］繼續"

# ---------- 對話 ----------

func _start_dialog(lines: Array, on_done: Callable) -> void:
	dialog_lines = lines.duplicate()
	dialog_done = on_done
	busy = true
	get_tree().paused = true
	dialog_back.visible = true
	prompt.text = ""
	_next_line()

func _next_line() -> void:
	if dialog_lines.is_empty():
		dialog_back.visible = false
		busy = false
		get_tree().paused = false
		dialog_done.call()
		return
	var l: Array = dialog_lines.pop_front()
	dialog_name.text = l[0]
	dialog_text.text = l[1]

func _advance_pressed(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

func _unhandled_input(event: InputEvent) -> void:
	if busy:
		if choice_box.visible or end_box.visible:
			return
		if _advance_pressed(event):
			get_viewport().set_input_as_handled()
			if card_label.visible:
				_next_card()
			elif dialog_back.visible:
				_next_line()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E and not jax.dead:
		var npc := _near_npc()
		if npc.is_empty():
			return
		get_viewport().set_input_as_handled()
		_interact(npc)

func _near_npc() -> Dictionary:
	if stage != "talk" and stage != "return":
		return {}
	var best := {}
	var best_d := TALK_RANGE
	for n in npcs:
		var d: float = Vector2(jax.global_position.x - n["pos"].x, jax.global_position.z - n["pos"].z).length()
		if d < best_d:
			best_d = d
			best = n
	return best

func _interact(_npc: Dictionary) -> void:
	SFX.play(self, "ui_click", -6.0)
	if stage == "talk":
		_start_dialog(TALK_LINES, func() -> void:
			PROGRESS.talked = true
			stage = "clear")
	elif stage == "return":
		_start_dialog(RETURN_LINES, _show_choice)

# ---------- 選擇與結局 ----------

func _show_choice() -> void:
	busy = true
	get_tree().paused = true
	for c in choice_box.get_children():
		c.queue_free()
	choice_box.visible = true
	var back := ColorRect.new()
	back.color = Color(0.1, 0.11, 0.15, 0.95)
	back.position = Vector2(110, 120)
	back.size = Vector2(420, 120)
	choice_box.add_child(back)
	var q := Label.new()
	q.text = "箱子裡有一批店家仍在使用的貨。"
	q.position = Vector2(110, 130)
	q.size = Vector2(420, 20)
	_style_label(q, 12)
	choice_box.add_child(q)
	var opts := [
		["照單交還，整件回收", "報酬較多。Bo 的工作枱少了零件。", "return"],
		["留下店家在用的貨", "Bo 保住工作枱，但清場組還會再來。", "keep"],
	]
	for i in opts.size():
		var b := Button.new()
		b.text = opts[i][0]
		b.position = Vector2(130, 160 + i * 38)
		b.size = Vector2(380, 32)
		b.tooltip_text = opts[i][1]
		b.pressed.connect(_choose.bind(opts[i][2]))
		choice_box.add_child(b)
		var d := Label.new()
		d.text = opts[i][1]
		d.position = Vector2(130, 175 + i * 38)
		d.size = Vector2(380, 14)
		d.add_theme_font_size_override("font_size", 8)
		d.add_theme_color_override("font_color", Color("9AA3AD"))
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice_box.add_child(d)

func _choose(which: String) -> void:
	SFX.play(self, "ui_click")
	PROGRESS.choice = which
	choice_box.visible = false
	jax.receipts += 6 if which == "return" else 3
	var lines: Array = RESULT_RETURN if which == "return" else RESULT_KEEP
	_start_dialog(lines + [ADA_LINE], _show_end)

func _show_end() -> void:
	stage = "done"
	busy = true
	get_tree().paused = true
	main.victory = true
	PROGRESS.chapter_done = true
	jax.save_progress(false)
	end_box.visible = true
	var back := ColorRect.new()
	back.color = Color("14161D")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_box.add_child(back)
	var lines := [
		["第一章　橋底街　完", 22, Color("E7DFC9")],
		["這一次：%s" % ("照單交還" if PROGRESS.choice == "return" else "留下店家在用的貨"), 11, Color("75C7B0")],
		["等級 %d　單據 %d　配件 %d 件" % [jax.level, jax.receipts, jax.inventory.size()], 11, Color("BCC5D4")],
		["第二章　散貨窗口　敬請期待", 11, Color("D6D573")],
	]
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i][0]
		l.position = Vector2(0, 70 + i * 32)
		l.size = Vector2(640, 30)
		_style_label(l, lines[i][1], lines[i][2])
		end_box.add_child(l)
	var again := Button.new()
	again.text = "再玩一次（保留成長）"
	again.position = Vector2(170, 250)
	again.size = Vector2(140, 30)
	again.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene())
	end_box.add_child(again)
	var title := Button.new()
	title.text = "回標題"
	title.position = Vector2(330, 250)
	title.size = Vector2(140, 30)
	title.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://game/title.tscn"))
	end_box.add_child(title)

# ---------- 每幀：目標、提示、階段 ----------

func _process(delta: float) -> void:
	if get_tree().paused and busy:
		return
	var cleared: int = main.camps_cleared()
	if cleared > camps_saved and not jax.dead:
		camps_saved = cleared
		jax.save_progress(false)
	var boss: Variant = main.boss
	if boss != null and is_instance_valid(boss) and boss.awake and not boss_woke:
		boss_woke = true
		_say_caption(BOSS_WAKE)
	if main.boss_down and not boss_down_shown:
		boss_down_shown = true
		_say_caption(BOSS_DOWN)
		stage = "return"
		jax.save_progress(false)
	caption_timer -= delta
	if caption_timer <= 0.0:
		caption.text = ""
	match stage:
		"talk":
			objective.text = "目標：走近 Bo，按［E］交談"
		"clear":
			if cleared < main.CAMPS.size() and boss_down_shown == false:
				objective.text = "目標：清理沿路的失控設備（%d／%d）" % [cleared, main.CAMPS.size()]
				if cleared >= main.CAMPS.size():
					objective.text = "目標：前往北面，擊敗頭目「收據」"
			else:
				objective.text = "目標：前往北面，擊敗頭目「收據」"
		"return":
			objective.text = "目標：回商店找 Bo，按［E］結算"
		_:
			objective.text = ""
	if stage == "clear" and cleared >= main.CAMPS.size():
		objective.text = "目標：前往北面，擊敗頭目「收據」"
	prompt.text = "［E］交談" if not _near_npc().is_empty() and not jax.dead else ""
	hint.text = _current_hint() if show_hints and stage == "clear" and not jax.dead else ""
	var bench_open: bool = main.get_node("HUD").bench.visible
	if bench_open:
		bench_opened = true
	overlay.visible = not bench_open or busy

func _say_caption(t: String) -> void:
	caption.text = t
	caption_timer = 4.5

func _current_hint() -> String:
	if not moved:
		if jax.global_position.distance_to(start_pos) > 3.0:
			moved = true
		return "WASD 移動（W＝畫面上方）"
	var any_awake := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.awake:
			any_awake = true
			break
	if any_awake and not skill_used:
		return "Q 或滑鼠右鍵：放大技（普通攻擊會自動出手）"
	if any_awake and not dashed:
		return "空白鍵：衝刺，期間無敵，用來躲開紅圈"
	if not bench_opened and jax.inventory.size() > 0:
		return "按 C 打開工作枱，裝上掉落的配件與裝備"
	return ""
