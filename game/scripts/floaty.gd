extends RefCounted
## 浮動傷害數字：在 3D 世界裡向上飄並淡出。

static func spawn(world: Node, pos: Vector3, text: String, color := Color("F4F0E4"), big := false) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.012 if big else 0.008
	l.font_size = 40
	l.outline_size = 10
	l.modulate = color
	l.outline_modulate = Color("14161D")
	world.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0.0, 0.0)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + 1.1, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)
