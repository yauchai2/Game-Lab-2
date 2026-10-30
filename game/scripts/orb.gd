extends Control
## 生命球：按血量比例填滿的圓球（仿 PoE 2 左下角紅球）。

var ratio := 1.0
var fill_color := Color("B8483B")
var label_text := ""
const R := 26.0

func _draw() -> void:
	var c := Vector2(R + 2, R + 2)
	draw_circle(c, R + 2, Color("3A3426"))
	draw_circle(c, R, Color("14120F"))
	if ratio > 0.0:
		var y_cut := c.y + R - 2.0 * R * clampf(ratio, 0.0, 1.0)
		var pts := PackedVector2Array()
		var steps := 40
		for i in steps + 1:
			var a := TAU * i / steps
			var p := c + Vector2(cos(a), sin(a)) * R
			if p.y >= y_cut:
				pts.append(p)
		if pts.size() >= 3:
			draw_colored_polygon(pts, fill_color)
	draw_arc(c, R, 0.0, TAU, 40, Color("7A6A3E"), 1.5)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, c + Vector2(-w * 0.5, 4), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("F4F0E4"))
