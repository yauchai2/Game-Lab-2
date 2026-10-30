extends "res://game/scripts/levels/level_base.gd"
## 章末高潮（一）：衝出封鎖線（正常戰鬥），上車後是純演出的高架橋追逐。玩家不駕駛、不操作。
## 旗標：chase_clear、chase_done。

var van: Node3D
var chase_cars: Array = []
var cinematic := false
var t := 0.0
const DURATION := 14.0
const ROAD_X := 300.0
var cam_set := false

func _ready() -> void:
	_setup_refs()
	outdoor(Color("4A3F6B"), Color("3B3F4E"), Vector2(22, 16))
	jax.global_position = Vector3(0, 0.87, 10)
	for p in [Vector3(-9, 0, -4), Vector3(9, 0, -4), Vector3(-14, 0, 5)]:
		box(p + Vector3(0, 0.9, 0), Vector3(3.4, 1.8, 1.8), NAVY, true)
		sign3d("封鎖", p + Vector3(0, 2.7, 0), 20, CORAL)
	van = _make_van(Vector3(0, 0, -12))
	person(Vector3(-1.0, 0.4, -11.3), Color("D6D573"), "Skye（駕駛）", 1.2)
	for x in [-6, -3, 4, 7]:
		spawn_enemy(Vector3(x, 0, -1), x > 0 and x != 4, "blockade", Color("292D3B"), 45, false)
	await get_tree().process_frame
	say("", "封鎖線橫在路中間。室友的車停在後面，引擎還沒發動。", 3.4)
	objective("突破封鎖線，掩護室友發動車輛")
	interact(Vector3(0, 0, -9.5), "上車", _board, 2.6).enabled = false

func _make_van(pos: Vector3) -> Node3D:
	var v := Node3D.new()
	v.position = pos
	add_child(v)
	box(Vector3(0, 0.9, 0), Vector3(2.6, 1.4, 5.2), Color("D6D573"), false, v)
	box(Vector3(0, 1.9, -1.0), Vector3(2.4, 0.9, 2.6), NAVY, false, v)
	box(Vector3(0, 0.3, 1.8), Vector3(2.7, 0.4, 1.4), Color("6B5440"), false, v)
	return v

func _process(delta: float) -> void:
	if jax == null:
		return
	if not cinematic and not CHAPTER.has("chase_clear"):
		if enemies_left("blockade") == 0 and Engine.get_process_frames() > 40:
			CHAPTER.set_flag("chase_clear")
			say("", "封鎖線破了。Skye 拍了拍車門，示意上車。", 3.0)
			objective("上車（走近車子按 E）")
			for it in get_tree().get_nodes_in_group("interactables"):
				if it.prompt == "上車":
					it.enabled = true
	if cinematic:
		_chase_tick(delta)

func _board() -> void:
	cinematic = true
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	objective("")
	jax.set_physics_process(false)
	jax.set_process_unhandled_input(false)
	# 把車與玩家搬到長長的高架橋上
	van.position = Vector3(ROAD_X, 0, 0)
	box(Vector3(ROAD_X, 0.0, -260), Vector3(14, 0.4, 600), Color("3B3F4E"))
	for i in 60:
		var z := -i * 10.0 + 20.0
		box(Vector3(ROAD_X, 0.25, z), Vector3(0.3, 0.05, 3.0), Color("E7DFC9"))
		for s in [-1, 1]:
			box(Vector3(ROAD_X + s * 7.3, 1.0, z), Vector3(0.3, 2.0, 0.3), NAVY)
			if i % 2 == 0:
				box(Vector3(ROAD_X + s * 7.3, 5.0, z), Vector3(1.4, 0.3, 0.5), Color("D6D573"))
			box(Vector3(ROAD_X + s * 20.0, 6.0 + (i % 3) * 3.0, z - 4.0), Vector3(8, 12 + (i % 3) * 6, 6), [Color("CC6657"), Color("859AC1"), Color("9B8ACC")][i % 3])
	for k in 3:
		var c := _make_van(Vector3(ROAD_X + (k - 1) * 4.0, 0, 12 + k * 5))
		c.get_child(0).get_node("Mesh").material_override = _mat(NAVY)
		chase_cars.append(c)
	var cam := get_viewport().get_camera_3d()
	cam.fov = 80.0
	cam.offset = Vector3(-5.5, 1.4, 6.5)
	cam_set = true
	say("", "（高架橋。追兵從後面咬上來。）", 3.2)
	say("Skye", "（單手握著方向盤，另一手把車窗外伸來的東西推開。）", 3.4)
	say("TK 清場組", "目標車輛，請靠邊。", 2.6)
	say("", "（你站在車斗上，頭盔裡聽到自己的呼吸聲。）", 3.0)

func _chase_tick(delta: float) -> void:
	t += delta
	van.position.z -= 30.0 * delta
	jax.global_position = van.global_position + Vector3(0, 1.5, 1.8)
	for i in chase_cars.size():
		var c: Node3D = chase_cars[i]
		c.position.z = van.position.z + 12.0 + i * 5.0 + sin(t * 2.0 + i) * 2.0
		c.position.x = ROAD_X + (i - 1) * 4.0 + sin(t * 1.5 + i * 2.0) * 2.0
	var cam := get_viewport().get_camera_3d()
	cam.look_at(van.global_position + Vector3(0, 1.2, 0))
	cam.fov = 80.0 + sin(t * 3.0) * 4.0
	if int(t * 2.0) != int((t - delta) * 2.0):
		main.get_node("HUD").lines.burst(1.0)
	if t >= DURATION:
		cinematic = false
		cam.fov = 60.0
		cam.offset = Vector3(0, 8.6, 12.3)
		_story_hud().title("登上運輸平台", "章末頭目在前方", 2.0)
		CHAPTER.set_flag("chase_done")
		get_tree().create_timer(1.8).timeout.connect(save_and_go.bind("convoy"))
