extends SceneTree
## godot --path . --rendering-method gl_compatibility --script tools/capture-jsr.gd
## (needs a display, e.g. xvfb-run). Saves the three acceptance frames at 640x360 and 1280x720.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: Node3D = load("res://game/scenes/jsr-test.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var shots := [
		["play", false, Vector3(12, 0, 2)],
		["low", true, Vector3(12, 0, 2)],
	]
	for res_index in [0, 2]:
		scene.resolution_index = res_index
		scene._apply_resolution()
		for s in shots:
			scene.showcase = s[1]
			scene.cam_target = s[2]
			scene._update_camera()
			await _save("jsr-%s-%d.png" % [s[0], scene.RESOLUTIONS[res_index].x])
		# Character close-up from the showcase camera.
		scene.showcase = true
		scene._update_camera()
		scene.show_cam.fov = 45.0
		scene.show_cam.position = scene.jax.position + Vector3(2.2, 1.2, 3.0)
		scene.show_cam.look_at(scene.jax.position + Vector3(0, 1.0, 0))
		await _save("jsr-closeup-%d.png" % scene.RESOLUTIONS[res_index].x)
		scene.show_cam.fov = 85.0
	quit()

func _save(filename: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var dest := ProjectSettings.globalize_path("res://docs/art/jsr/" + filename)
	DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
	print("Saved ", dest, " ", picture.get_size(), " err=", picture.save_png(dest))
