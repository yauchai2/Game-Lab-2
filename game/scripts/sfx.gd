extends RefCounted
## 音效播放：Sfx.play(self, "slam")。音效檔由 tools/audio/make_sfx.py 合成，放在 assets/audio/sfx/。

const DIR := "res://assets/audio/sfx/"
static var cache := {}

static func play(ctx: Node, sfx_name: String, volume_db := 0.0, pitch_var := 0.06) -> void:
	if not cache.has(sfx_name):
		cache[sfx_name] = load(DIR + sfx_name + ".wav")
	var stream: AudioStream = cache[sfx_name]
	if stream == null or not ctx.is_inside_tree():
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.finished.connect(p.queue_free)
	ctx.get_tree().root.add_child(p)
	p.play()
