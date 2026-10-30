extends Control
## Radiating manga-style speed lines drawn over the screen for a split second.

var time_left := 0.0
var duration := 0.3
var strength := 1.0
var lines: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func burst(power := 1.0) -> void:
	strength = power
	duration = 0.22 + 0.12 * power
	time_left = duration
	lines.clear()
	var count := int(22 + 18 * power)
	for i in count:
		lines.append({
			"angle": randf() * TAU,
			"inner": randf_range(95.0, 150.0),
			"length": randf_range(50.0, 130.0) * (0.7 + 0.5 * power),
		})
	queue_redraw()

func _process(delta: float) -> void:
	if time_left > 0.0:
		time_left -= delta
		queue_redraw()

func _draw() -> void:
	if time_left <= 0.0:
		return
	var alpha := clampf(time_left / duration, 0.0, 1.0)
	var center := get_viewport_rect().size / 2.0
	for l in lines:
		var dir := Vector2.from_angle(l["angle"])
		var p0: Vector2 = center + dir * float(l["inner"])
		var p1: Vector2 = p0 + dir * float(l["length"]) * (1.0 + (1.0 - alpha) * 0.5)
		draw_line(p0, p1, Color(1, 1, 1, alpha * 0.85), 1.0 + strength)
