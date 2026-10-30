extends Camera3D

@export var follow: Node3D
@export var offset := Vector3(0, 12, 10)
@export var smoothing := 8.0

func _ready() -> void:
	if follow:
		global_position = follow.global_position + offset

func _process(delta: float) -> void:
	if follow:
		var goal := follow.global_position + offset
		global_position = global_position.lerp(goal, 1.0 - exp(-smoothing * delta))
