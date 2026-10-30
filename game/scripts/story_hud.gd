extends CanvasLayer
## 劇情用介面：目標、互動提示、字幕、標題字卡。畫面固定 640x360。

var objective := Label.new()
var prompt := Label.new()
var sub_back := ColorRect.new()
var sub := Label.new()
var title_label := Label.new()
var title_sub := Label.new()
var title_tween: Tween
var queue: Array = []
var sub_left := 0.0

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	objective.position = Vector2(300, 8)
	objective.size = Vector2(332, 24)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(objective, 10)
	add_child(objective)
	prompt.position = Vector2(170, 296)
	prompt.size = Vector2(300, 14)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(prompt, 10)
	prompt.add_theme_color_override("font_color", Color("D6D573"))
	add_child(prompt)
	sub_back.color = Color(0.16, 0.18, 0.23, 0.82)
	sub_back.position = Vector2(80, 316)
	sub_back.size = Vector2(480, 34)
	sub_back.visible = false
	add_child(sub_back)
	sub.position = Vector2(6, 2)
	sub.size = Vector2(468, 30)
	sub.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	sub.add_theme_font_size_override("font_size", 10)
	sub_back.add_child(sub)
	title_label.size = Vector2(640, 40)
	title_label.position = Vector2(0, 120)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(title_label, 28)
	title_label.add_theme_color_override("font_color", Color("E7DFC9"))
	title_label.modulate.a = 0.0
	add_child(title_label)
	title_sub.size = Vector2(640, 16)
	title_sub.position = Vector2(0, 162)
	title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(title_sub, 10)
	title_sub.modulate.a = 0.0
	add_child(title_sub)

func _style(l: Label, size: int) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color("292D3B"))
	l.add_theme_constant_override("outline_size", 4)

func set_objective(text: String) -> void:
	objective.text = "目標：" + text if text != "" else ""

func set_prompt(text: String) -> void:
	prompt.text = text

## 字幕：speaker 可留空。會排隊依序顯示。
func say(speaker: String, text: String, seconds := 2.8) -> void:
	queue.append({"text": ("%s：%s" % [speaker, text]) if speaker != "" else text, "t": seconds})

func is_talking() -> bool:
	return sub_back.visible or not queue.is_empty()

func title(text: String, subtitle := "", seconds := 2.4) -> void:
	title_label.text = text
	title_sub.text = subtitle
	if title_tween:
		title_tween.kill()
	title_tween = create_tween()
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	title_tween.parallel().tween_property(title_sub, "modulate:a", 1.0, 0.3)
	title_tween.tween_interval(seconds)
	title_tween.tween_property(title_label, "modulate:a", 0.0, 0.5)
	title_tween.parallel().tween_property(title_sub, "modulate:a", 0.0, 0.5)

func _process(delta: float) -> void:
	if sub_left > 0.0:
		sub_left -= delta
		if sub_left <= 0.0:
			sub_back.visible = false
	if sub_left <= 0.0 and not queue.is_empty():
		var line: Dictionary = queue.pop_front()
		sub.text = line["text"]
		sub_left = line["t"]
		sub_back.visible = true
