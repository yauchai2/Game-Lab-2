extends RefCounted
## 玩家設定：存在 user://settings.cfg；音量、畫面、效果與操作手感。
## 用法：GameSettings.v["shake"]；改完呼叫 apply(tree) 並 save()。

const PATH := "user://settings.cfg"
const FISHEYE_K := [0.0, 0.18, 0.35, 0.5]
const RENDER_WIDTHS := [960, 1280, 1920, 0]  # 0 = 原生解析度
const SHAKE_MULT := [0.0, 0.5, 1.0]
const ZOOM_STEP := [0.05, 0.1, 0.18]

const DEFAULTS := {
	"master": 100, "music": 70, "sfx": 100,
	"fullscreen": 0, "render": 1, "fisheye": 2, "shadows": 1, "vsync": 1,
	"shake": 2, "hit_stop": 1, "damage_numbers": 1, "zoom_speed": 1, "hide_common": 0, "toon": 1, "outline": 1,
}

## 調色強度（0＝關）。暫時不調色，之後按章節內容設定，由章節程式改這個值。
static var grade_strength := 0.0
static var v := DEFAULTS.duplicate()
static var loaded := false

static func load_settings() -> void:
	loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in DEFAULTS:
		v[k] = int(cf.get_value("settings", k, DEFAULTS[k]))

static func save() -> void:
	var cf := ConfigFile.new()
	for k in v:
		cf.set_value("settings", k, v[k])
	cf.save(PATH)

static func reset() -> void:
	v = DEFAULTS.duplicate()

static func _ensure_buses() -> void:
	for n in ["Music", "SFX"]:
		if AudioServer.get_bus_index(n) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")

static func _set_vol(bus: String, percent: int) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(percent / 100.0, 0.0001)))
		AudioServer.set_bus_mute(i, percent <= 0)

static func fit_3d(tree: SceneTree) -> void:
	var root := tree.root
	var w: int = RENDER_WIDTHS[v["render"]]
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root.scaling_3d_scale = 1.0 if w == 0 else clampf(float(w) / maxf(float(root.get_window().size.x), 1.0), 0.25, 1.0)

static func apply(tree: SceneTree) -> void:
	if not loaded:
		load_settings()
	_ensure_buses()
	_set_vol("Master", v["master"])
	_set_vol("Music", v["music"])
	_set_vol("SFX", v["sfx"])
	var win := tree.root.get_window()
	win.mode = Window.MODE_FULLSCREEN if v["fullscreen"] == 1 else Window.MODE_WINDOWED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v["vsync"] == 1 else DisplayServer.VSYNC_DISABLED)
	for sun in tree.get_nodes_in_group("sun"):
		sun.shadow_enabled = v["shadows"] == 1
	fit_3d(tree)
	tree.call_group("toon", "refresh")

static func fisheye_k() -> float:
	return FISHEYE_K[v["fisheye"]]
