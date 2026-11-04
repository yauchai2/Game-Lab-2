extends SceneTree
## Run with a real display (software OpenGL is sufficient):
## godot --path . --rendering-method gl_compatibility --script tools/capture-preview.gd
## Writes actual engine screenshots; --headless uses a dummy renderer and cannot capture.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: Node3D = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	# Freeze gameplay only, so all views show the same deterministic initial state.
	for actor in get_nodes_in_group("enemies") + get_nodes_in_group("player"):
		actor.set_physics_process(false)
	await _save("gameplay-preview.png")
	var hud: CanvasLayer = scene.get_node("HUD")
	hud.toggle_bench()
	await _save("bench-preview.png")
	hud.toggle_bench()
	hud.hide()
	var camera: Camera3D = scene.get_node("Camera3D")
	camera.set_process(false)
	camera.fov = 78.0
	camera.position = Vector3(3.2, 1.8, 15.5)
	camera.look_at(Vector3(0, 1.3, 7))
	await _save("street-preview.png")
	scene.queue_free()
	for i in 4:
		await process_frame
	quit()

func _save(filename: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if picture == null or picture.is_empty():
		push_error("Capture requires a rendering display, not the headless dummy driver.")
		quit(1)
		return
	var destination := "res://docs/art/" + filename
	var error := picture.save_png(destination)
	if error != OK:
		push_error("Could not save " + destination)
		quit(1)
	print("Saved ", destination)
