extends Camera3D

@export var follow: Node3D
@export var offset := Vector3(0, 8.6, 12.3)
@export var smoothing := 8.0

var shake := 0.0

func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)

func _ready() -> void:
	if follow:
		global_position = follow.global_position + offset

func _process(delta: float) -> void:
	if follow:
		var goal := follow.global_position + offset
		global_position = global_position.lerp(goal, 1.0 - exp(-smoothing * delta))
	shake = move_toward(shake, 0.0, delta * 1.5)
	h_offset = randf_range(-1.0, 1.0) * shake
	v_offset = randf_range(-1.0, 1.0) * shake
