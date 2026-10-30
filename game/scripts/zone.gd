extends Node3D
## Ground zone: telegraph (damage 0) or lingering hazard that ticks damage on enemies inside.

var radius := 2.0
var life := 3.0
var damage := 8
var color := Color("CC6657")
var tick := 0.5

func _ready() -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.05
	mi.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, 0.4)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	add_child(mi)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if damage <= 0:
		return
	tick -= delta
	if tick <= 0.0:
		tick = 0.5
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var d: Vector3 = enemy.global_position - global_position
			d.y = 0.0
			if d.length() <= radius:
				enemy.take_damage(damage, global_position)
