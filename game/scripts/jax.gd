extends CharacterBody3D

@export var speed := 6.0
@export var gravity := 20.0
@export var skill_cooldown := 1.5
@export var skill_windup := 0.3
@export var skill_radius := 3.5
@export var skill_damage := 25

var target := Vector3.ZERO
var has_target := false
var skill_timer := 0.0
var windup_left := -1.0
var anim_time := 0.0

@onready var model: Node3D = $Model
@onready var leg_l: Node3D = model.find_child("LegL", true, false)
@onready var leg_r: Node3D = model.find_child("LegR", true, false)
@onready var arm_l: Node3D = model.find_child("ArmL", true, false)
@onready var arm_r: Node3D = model.find_child("ArmR", true, false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_click_move(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			use_skill()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		use_skill()

func _click_move(screen_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		target = hit.position
		has_target = true

# 拆場: short windup, then a shockwave that hits every enemy in range.
func use_skill() -> void:
	if skill_timer > 0.0 or windup_left >= 0.0:
		return
	has_target = false
	windup_left = skill_windup
	skill_timer = skill_cooldown

func _slam() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var away: Vector3 = enemy.global_position - global_position
		away.y = 0.0
		if away.length() <= skill_radius:
			enemy.take_damage(skill_damage)
	_spawn_shockwave()

func _spawn_shockwave() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	ring.mesh = torus
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("CC6657")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = m
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.1 - 0.87, 0)
	ring.scale = Vector3(0.3, 0.3, 0.3)
	var tween := ring.create_tween()
	var final_scale := skill_radius
	tween.tween_property(ring, "scale", Vector3(final_scale, 1.0, final_scale), 0.25)
	tween.tween_callback(ring.queue_free)

func _physics_process(delta: float) -> void:
	skill_timer = maxf(skill_timer - delta, 0.0)
	var move := Vector3.ZERO
	if windup_left >= 0.0:
		windup_left -= delta
		model.rotation.x = lerpf(model.rotation.x, -0.4, 0.4)
		if windup_left < 0.0:
			_slam()
	elif has_target:
		var dir := target - global_position
		dir.y = 0.0
		if dir.length() < 0.2:
			has_target = false
		else:
			move = dir.normalized() * speed
			look_at(global_position + dir, Vector3.UP)
	if windup_left < 0.0:
		model.rotation.x = lerpf(model.rotation.x, 0.0, 0.3)
	velocity.x = move.x
	velocity.z = move.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	_animate_limbs(delta, move.length() > 0.1)

func _animate_limbs(delta: float, moving: bool) -> void:
	var swing := 0.0
	if moving:
		anim_time += delta * speed * 1.8
		swing = sin(anim_time) * 0.6
	for pair in [[leg_l, swing], [leg_r, -swing], [arm_l, -swing * 0.8], [arm_r, swing * 0.8]]:
		var limb: Node3D = pair[0]
		if limb:
			limb.rotation.x = lerpf(limb.rotation.x, pair[1], 0.4)
