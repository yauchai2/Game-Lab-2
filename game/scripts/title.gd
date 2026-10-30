extends Control
## 標題畫面：新遊戲、繼續（有存檔才可用）。

const PROGRESS := preload("res://game/scripts/progress.gd")
const SFX := preload("res://game/scripts/sfx.gd")

var stage := Control.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# 640×360 的內容區置中；背景鋪滿整個視窗（低解像度畫面會隨視窗擴展）
	stage.anchor_left = 0.5
	stage.anchor_right = 0.5
	stage.anchor_top = 0.5
	stage.anchor_bottom = 0.5
	stage.offset_left = -320.0
	stage.offset_right = 320.0
	stage.offset_top = -180.0
	stage.offset_bottom = 180.0
	add_child(stage)
	var bg := ColorRect.new()
	bg.color = Color("20232E")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)
	# 斜向色帶：呼應斜向等距的街區
	var bands := [[Color("3A4054"), 90.0, 40.0], [Color("4A6A66"), 200.0, 14.0], [Color("CC6657"), 300.0, 8.0]]
	for b in bands:
		var r := ColorRect.new()
		r.color = b[0]
		r.size = Vector2(3200, b[2])
		r.position = Vector2(-1280, b[1])
		r.pivot_offset = Vector2(1600, b[2] / 2.0)
		r.rotation = deg_to_rad(-20)
		stage.add_child(r)
	_text("疊域", Vector2(0, 52), 54, Color("E7DFC9"))
	_text("第一章　橋底街", Vector2(0, 120), 14, Color("75C7B0"))
	_text("TURB　整件回收　取消費另計", Vector2(0, 336), 9, Color("9AA3AD"))
	var y := 176
	var new_btn := _button("新遊戲", Vector2(270, y))
	new_btn.pressed.connect(_new_game)
	var cont := _button("繼續", Vector2(270, y + 36))
	cont.disabled = not PROGRESS.has_save()
	cont.pressed.connect(_continue)
	_text("WASD 移動　Q／右鍵 技能　空白鍵 衝刺　C 工作枱", Vector2(0, 318), 9, Color("BCC5D4"))

func _text(t: String, pos: Vector2, font_px: int, color: Color) -> void:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = Vector2(640, font_px + 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", color)
	stage.add_child(l)

func _button(t: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = Vector2(100, 28)
	stage.add_child(b)
	return b

func _new_game() -> void:
	SFX.play(self, "ui_click")
	get_tree().change_scene_to_file("res://game/select.tscn")

func _continue() -> void:
	SFX.play(self, "ui_click")
	if PROGRESS.load_from_disk():
		get_tree().change_scene_to_file("res://game/main.tscn")
