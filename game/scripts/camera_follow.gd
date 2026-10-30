extends Camera3D
## 自由視角鏡頭：預設 45 度斜向等距俯視；按住滑鼠中鍵拖曳（或按 [ ]）轉動，滾輪縮放。
## 移動時平滑跟隨並稍微領前，頭目戰自動拉遠。

@export var follow: Node3D
@export var distance := 15.0
@export var smoothing := 8.0
@export var yaw_deg := 45.0
@export var pitch_deg := 35.0
@export var lead_distance := 1.6
@export var zoom_min := 0.35
@export var zoom_max := 2.2
@export var boss_zoom := 1.35

const PITCH_MIN := 18.0
const PITCH_MAX := 75.0

var shake := 0.0
var zoom := 1.0
var zoom_goal := 1.0
var boss_blend := 0.0
var lead := Vector3.ZERO
var dragging := false

func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)

func _ready() -> void:
	_apply_rotation()
	if follow:
		global_position = follow.global_position + _orbit_offset()

func _apply_rotation() -> void:
	rotation = Vector3(-deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)

func _orbit_offset() -> Vector3:
	var p := deg_to_rad(pitch_deg)
	return Basis(Vector3.UP, deg_to_rad(yaw_deg)) * Vector3(0.0, sin(p), cos(p)) * distance * zoom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_goal = clampf(zoom_goal * 0.9, zoom_min, zoom_max)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_goal = clampf(zoom_goal * 1.1, zoom_min, zoom_max)
	elif event is InputEventMouseMotion and dragging:
		yaw_deg = wrapf(yaw_deg - event.relative.x * 0.25, 0.0, 360.0)
		pitch_deg = clampf(pitch_deg + event.relative.y * 0.2, PITCH_MIN, PITCH_MAX)

func _process(delta: float) -> void:
	var turn := 0.0
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		turn += 1.0
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		turn -= 1.0
	yaw_deg = wrapf(yaw_deg + turn * 90.0 * delta, 0.0, 360.0)
	_apply_rotation()
	if follow:
		var boss: Variant = get_parent().get("boss")
		var boss_fight: bool = boss != null and is_instance_valid(boss) and boss.hp > 0 and boss.awake
		boss_blend = move_toward(boss_blend, 1.0 if boss_fight else 0.0, delta * 0.5)
		zoom = lerpf(zoom, zoom_goal, 1.0 - exp(-6.0 * delta))
		var vel: Vector3 = follow.velocity if "velocity" in follow else Vector3.ZERO
		vel.y = 0.0
		var lead_goal := vel.normalized() * lead_distance if vel.length() > 0.5 else Vector3.ZERO
		lead = lead.lerp(lead_goal, 1.0 - exp(-3.0 * delta))
		var goal := follow.global_position + lead + _orbit_offset() * lerpf(1.0, boss_zoom, boss_blend)
		global_position = global_position.lerp(goal, 1.0 - exp(-smoothing * delta))
	shake = move_toward(shake, 0.0, delta * 1.5)
	h_offset = randf_range(-1.0, 1.0) * shake
	v_offset = randf_range(-1.0, 1.0) * shake
