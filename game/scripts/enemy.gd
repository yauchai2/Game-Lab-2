extends StaticBody3D

@export var max_hp := 60
@export var base_color := Color("8C9871")

var hp := max_hp
var _material := StandardMaterial3D.new()

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_material.albedo_color = base_color
	mesh.material_override = _material

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	_material.albedo_color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color", base_color, 0.2)
	if hp <= 0:
		remove_from_group("enemies")
		var die := create_tween()
		die.tween_property(self, "scale", Vector3(1.2, 0.01, 1.2), 0.25)
		die.tween_callback(queue_free)
