extends Camera3D
## 固定 45 度斜向等距俯視（不能轉），但鏡頭會平滑跟隨、移動時稍微領前、
## 頭目戰自動拉遠，並可用滾輪縮放。

@export var follow: Node3D
@export var offset := Vector3(0, 8.6, 12.3)
@export var smoothing := 8.0
@export var yaw_deg := 45.0
@export var lead_distance := 1.6
@export var zoom_min := 0.6
@export var zoom_max := 1.7
@export var boss_zoom := 1.35

var shake := 0.0
var zoom := 1.0
var zoom_goal := 1.0
var boss_blend := 0.0
var lead := Vector3.ZERO

func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)

func _ready() -> void:
	rotation.y = deg_to_rad(yaw_deg)
	if follow:
		global_position = follow.global_position + _rotated_offset()

func _rotated_offset() -> Vector3:
	return Basis(Vector3.UP, deg_to_rad(yaw_deg)) * offset * zoom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_goal = clampf(zoom_goal - 0.1, zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_goal = clampf(zoom_goal + 0.1, zoom_min, zoom_max)

func _process(delta: float) -> void:
	if follow:
		var boss: Variant = get_parent().get("boss")
		var boss_fight: bool = boss != null and is_instance_valid(boss) and boss.hp > 0 and boss.awake
		boss_blend = move_toward(boss_blend, 1.0 if boss_fight else 0.0, delta * 0.5)
		zoom = lerpf(zoom, zoom_goal, 1.0 - exp(-6.0 * delta))
		var vel: Vector3 = follow.velocity if "velocity" in follow else Vector3.ZERO
		vel.y = 0.0
		var lead_goal := vel.normalized() * lead_distance if vel.length() > 0.5 else Vector3.ZERO
		lead = lead.lerp(lead_goal, 1.0 - exp(-3.0 * delta))
		var dist := lerpf(1.0, boss_zoom, boss_blend)
		var goal := follow.global_position + lead + _rotated_offset() * dist
		global_position = global_position.lerp(goal, 1.0 - exp(-smoothing * delta))
	shake = move_toward(shake, 0.0, delta * 1.5)
	h_offset = randf_range(-1.0, 1.0) * shake
	v_offset = randf_range(-1.0, 1.0) * shake
