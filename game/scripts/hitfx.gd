extends RefCounted
## 打擊感小工具：火花、頓幀、鏡頭震動。

static var stopping := false
static var last_stop := 0

static func sparks(world: Node, pos: Vector3, color: Color, amount := 8, power := 1.0) -> void:
	var p := CPUParticles3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = mat
	p.mesh = box
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.45
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 2.0 * power
	p.initial_velocity_max = 5.5 * power
	p.gravity = Vector3(0, -14, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	world.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(0.8).timeout.connect(p.queue_free)

static func hit_stop(tree: SceneTree, duration: float) -> void:
	var now := Time.get_ticks_msec()
	if stopping or now - last_stop < 300:
		return
	last_stop = now
	stopping = true
	Engine.time_scale = 0.06
	tree.create_timer(duration, true, false, true).timeout.connect(func() -> void:
		Engine.time_scale = 1.0
		stopping = false)

static func shake(world: Node, amount: float) -> void:
	var cam := world.get_viewport().get_camera_3d()
	if cam and cam.has_method("add_shake"):
		cam.add_shake(amount)

