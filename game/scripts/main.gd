extends Node3D

const SFX := preload("res://game/scripts/sfx.gd")
const ENEMY_SCENE := preload("res://game/enemy.tscn")
const BOSS_SCENE := preload("res://game/boss.tscn")
const BOSS_POS := Vector3(0, 0.05, -17)
const START_POS := Vector3(0, 0.87, 11)
## 據點：位置、近戰數量、遠程數量。由近至遠，玩家自己推進。
const CAMPS := [
	{"pos": Vector3(-7, 0, 2), "melee": 3, "ranged": 0},
	{"pos": Vector3(8, 0, -3), "melee": 3, "ranged": 1},
	{"pos": Vector3(-8, 0, -8), "melee": 4, "ranged": 1},
	{"pos": Vector3(9, 0, -12), "melee": 3, "ranged": 2},
]

const MUSIC := {
	"explore": preload("res://assets/audio/music/explore-dark-city.ogg"),
	"boss": preload("res://assets/audio/music/boss-dark-forces.ogg"),
}
const MUSIC_DB := -14.0

var boss: Node = null
var victory := false
var boss_down := false
var chapter: Node
var music := AudioStreamPlayer.new()
var music_track := ""
var music_on := true

@onready var jax: CharacterBody3D = $Jax

# 場地邊界：看不見的牆，角色與敵人都不會走出街區。
const BOUNDS_X := 22.0
const BOUNDS_Z_NORTH := -21.0
const BOUNDS_Z_SOUTH := 19.0

func _add_boundary() -> void:
	var walls := [
		[Vector3(-BOUNDS_X - 1.0, 5.0, (BOUNDS_Z_NORTH + BOUNDS_Z_SOUTH) / 2.0), Vector3(2.0, 10.0, 80.0)],
		[Vector3(BOUNDS_X + 1.0, 5.0, (BOUNDS_Z_NORTH + BOUNDS_Z_SOUTH) / 2.0), Vector3(2.0, 10.0, 80.0)],
		[Vector3(0.0, 5.0, BOUNDS_Z_NORTH - 1.0), Vector3(80.0, 10.0, 2.0)],
		[Vector3(0.0, 5.0, BOUNDS_Z_SOUTH + 1.0), Vector3(80.0, 10.0, 2.0)],
	]
	for w in walls:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[1]
		shape.shape = box
		body.add_child(shape)
		add_child(body)
		body.global_position = w[0]

## 3D 畫面固定渲染成約 1280 闊（低解像度），介面則用視窗原生解像度畫，所以字永遠清晰。
const RENDER_WIDTH := 1280.0

func _fit_3d_resolution() -> void:
	var root := get_tree().root
	var window_w := float(root.get_window().size.x)
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root.scaling_3d_scale = clampf(RENDER_WIDTH / maxf(window_w, 1.0), 0.25, 1.0)

func _ready() -> void:
	_fit_3d_resolution()
	get_tree().root.size_changed.connect(_fit_3d_resolution)
	_add_boundary()
	jax.global_position = START_POS
	for i in CAMPS.size():
		_spawn_camp(i)
	_spawn_boss()
	chapter = CanvasLayer.new()
	chapter.set_script(preload("res://game/scripts/chapter.gd"))
	add_child(chapter)
	var loot_labels := CanvasLayer.new()
	loot_labels.set_script(preload("res://game/scripts/loot_labels.gd"))
	add_child(loot_labels)
	var fisheye := CanvasLayer.new()
	fisheye.set_script(preload("res://game/scripts/fisheye.gd"))
	add_child(fisheye)
	add_child(music)
	music.volume_db = MUSIC_DB
	_play_music("explore")

# 背景音樂：探索一首，頭目醒來換另一首；按 M 開關。
func _play_music(track: String) -> void:
	if track == music_track:
		return
	music_track = track
	var stream: AudioStreamOggVorbis = MUSIC[track]
	stream.loop = true
	music.stream = stream
	if music_on and track != "":
		music.play()

func _process(_delta: float) -> void:
	if victory or jax.dead:
		if music.playing:
			music.stop()
		return
	if boss != null and is_instance_valid(boss) and boss.awake:
		_play_music("boss")
	elif boss_down:
		_play_music("explore")

func _spawn_camp(index: int) -> void:
	var camp: Dictionary = CAMPS[index]
	var total: int = camp["melee"] + camp["ranged"]
	for i in total:
		var enemy := ENEMY_SCENE.instantiate()
		enemy.awake = false
		enemy.camp = "camp_%d" % index
		enemy.max_hp = 40 + index * 8
		if i >= camp["melee"]:
			enemy.ranged = true
			enemy.max_hp = 25 + index * 5
			enemy.base_color = Color("9B8ACC")
			enemy.element = ["phys", "fire", "cold", "lightning"][index]
		# 精英：第 3、4 個據點各有一隻大怪（血多、韌性高，要用技能重擊才打得破）
		if index >= 2 and i == 0:
			enemy.big = true
			enemy.max_hp *= 3
			enemy.attack_damage = int(enemy.attack_damage * 1.6)
			enemy.base_color = Color("8C4F45")
			enemy.scale = Vector3(1.35, 1.35, 1.35)
		add_child(enemy)
		var a := TAU * i / total
		enemy.global_position = camp["pos"] + Vector3(cos(a), 0.05, sin(a)) * 2.0

func _spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate()
	boss.awake = false
	add_child(boss)
	boss.global_position = BOSS_POS
	boss.defeated.connect(func() -> void:
		boss_down = true
		boss = null
		SFX.play(self, "victory"))

func camps_cleared() -> int:
	var n := 0
	for i in CAMPS.size():
		if get_tree().get_nodes_in_group("camp_%d" % i).is_empty():
			n += 1
	return n

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		music_on = not music_on
		if music_on and not victory and not jax.dead:
			music.play()
		else:
			music.stop()
