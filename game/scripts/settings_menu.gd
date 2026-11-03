extends CanvasLayer
## 設定頁：標題畫面按「設定」開啟；遊戲中按 Esc 開啟（會暫停，並可回標題）。
## 用法：SettingsMenu.open(self, in_game)

const GS := preload("res://game/scripts/game_settings.gd")
const SFX := preload("res://game/scripts/sfx.gd")
const TITLE_SCENE := "res://game/title.tscn"

# 每項：[設定鍵, 名稱, 類型, 選項]；類型 slider 為 0–100，cycle 為選項循環
const LEFT := [
	["master", "主音量", "slider", []],
	["music", "音樂", "slider", []],
	["sfx", "音效", "slider", []],
	["fullscreen", "顯示模式", "cycle", ["視窗", "全螢幕"]],
	["render", "3D 解析度", "cycle", ["低（960）", "標準（1280）", "高（1920）", "原生"]],
	["fisheye", "魚眼強度", "cycle", ["關", "弱", "標準", "強"]],
	["shadows", "陰影", "cycle", ["關", "開"]],
	["vsync", "垂直同步", "cycle", ["關", "開"]],
]
const RIGHT := [
	["shake", "鏡頭晃動", "cycle", ["關", "弱", "標準"]],
	["hit_stop", "打擊頓幀", "cycle", ["關", "開"]],
	["damage_numbers", "傷害數字", "cycle", ["關", "開"]],
	["zoom_speed", "滾輪縮放速度", "cycle", ["慢", "標準", "快"]],
	["hide_common", "隱藏白色掉落名牌", "cycle", ["關", "開"]],
	["toon", "卡通光影", "cycle", ["關", "開"]],
]
const KEYS_TEXT := "操作\nWASD 移動　空白鍵 翻滾\nQ／E／R／F 技能　Shift 格擋\n滑鼠中鍵拖曳 轉鏡頭　滾輪 縮放\nC 工作枱　Z 隱藏白色名牌\nM 音樂　V 魚眼\nEsc 設定"

var in_game := false
var was_paused := false
var host: Node
var stage := Control.new()
var value_labels := {}

static func open(parent: Node, from_game: bool) -> void:
	var m := CanvasLayer.new()
	m.set_script(load("res://game/scripts/settings_menu.gd"))
	m.in_game = from_game
	m.host = parent
	parent.add_child(m)

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	if in_game:
		was_paused = get_tree().paused
		get_tree().paused = true
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.05, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	stage.anchor_left = 0.5
	stage.anchor_right = 0.5
	stage.anchor_top = 0.5
	stage.anchor_bottom = 0.5
	stage.offset_left = -320.0
	stage.offset_right = 320.0
	stage.offset_top = -180.0
	stage.offset_bottom = 180.0
	stage.pivot_offset = Vector2(320, 180)
	stage.scale = Vector2(1.5, 1.5)
	root.add_child(stage)
	_build()

func _build() -> void:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("14120F")
	sb.border_color = Color("7A6A3E")
	sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(20, 14)
	panel.size = Vector2(600, 332)
	stage.add_child(panel)
	_label("設定", Vector2(36, 20), 14, Color("E6D9B5"))
	_label("畫面與音量", Vector2(36, 42), 9, Color("8C8470"))
	_label("效果與操作", Vector2(334, 42), 9, Color("8C8470"))
	for i in LEFT.size():
		_row(LEFT[i], Vector2(36, 58 + i * 26))
	for i in RIGHT.size():
		_row(RIGHT[i], Vector2(334, 58 + i * 26))
	var keys := _label(KEYS_TEXT, Vector2(334, 196), 9, Color("9AA3AD"))
	keys.size = Vector2(270, 110)
	var reset := _button("恢復預設", Vector2(36, 310), 90)
	reset.pressed.connect(_on_reset)
	var back := _button("返回遊戲" if in_game else "返回", Vector2(450, 310), 80)
	back.pressed.connect(close)
	if in_game:
		var title := _button("回標題", Vector2(538, 310), 70)
		title.pressed.connect(_to_title)

func _label(t: String, pos: Vector2, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(l)
	return l

func _button(t: String, pos: Vector2, w: float) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = Vector2(w, 24)
	b.add_theme_font_size_override("font_size", 10)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("3D372D") if st == "hover" else Color("221F1A")
		sb.border_color = Color("7A6A3E")
		sb.set_border_width_all(1)
		b.add_theme_stylebox_override(st, sb)
	stage.add_child(b)
	return b

func _row(item: Array, pos: Vector2) -> void:
	var key: String = item[0]
	_label(item[1], pos + Vector2(0, 3), 10, Color("C9BC9A"))
	if item[2] == "slider":
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 100
		s.step = 5
		s.value = GS.v[key]
		s.position = pos + Vector2(82, 6)
		s.size = Vector2(130, 14)
		s.value_changed.connect(func(val: float) -> void:
			GS.v[key] = int(val)
			value_labels[key].text = str(int(val))
			_changed())
		stage.add_child(s)
		var vl := _label(str(GS.v[key]), pos + Vector2(222, 3), 10, Color("E6D9B5"))
		value_labels[key] = vl
	else:
		var opts: Array = item[3]
		var b := _button(opts[GS.v[key]], pos + Vector2(82, 0), 140)
		b.pressed.connect(func() -> void:
			GS.v[key] = (GS.v[key] + 1) % opts.size()
			b.text = opts[GS.v[key]]
			SFX.play(self, "ui_click", -4.0)
			_changed())

func _changed() -> void:
	GS.apply(get_tree())
	GS.save()

func _on_reset() -> void:
	GS.reset()
	_changed()
	for c in stage.get_children():
		c.queue_free()
	value_labels.clear()
	_build()

func close() -> void:
	SFX.play(self, "ui_click", -4.0)
	if in_game:
		get_tree().paused = was_paused
	queue_free()

func _to_title() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(TITLE_SCENE)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
