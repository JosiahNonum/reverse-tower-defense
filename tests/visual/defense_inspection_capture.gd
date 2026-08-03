extends SceneTree


const CAPTURES: Array[Dictionary] = [
	{"name": "inspection_1280x720", "size": Vector2i(1280, 720)},
	{"name": "inspection_1440x900", "size": Vector2i(1440, 900)},
	{"name": "inspection_1024x768", "size": Vector2i(1024, 768)},
]


func _initialize() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	var output_directory: String = _output_directory(
		OS.get_cmdline_user_args(),
	)
	var absolute_directory: String = ProjectSettings.globalize_path(output_directory)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		push_error("VISUAL CHECK FAIL: could not create %s" % absolute_directory)
		quit(1)
		return

	var packed: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	var main := packed.instantiate() as MainCompositionRoot
	root.add_child(main)
	main.compose()
	var is_authoring: bool = _is_authoring(OS.get_cmdline_user_args())
	if is_authoring:
		main.begin_authoring_for_visual_check()
		var composer: WaveComposerPanel = main.get_wave_composer_panel()
		composer.add_unit(&"unit.swarm")
		composer.add_unit(&"unit.runner")
		composer.add_unit(&"unit.support")
		composer.add_unit(&"unit.tank")
	await process_frame
	await process_frame

	for capture: Dictionary in CAPTURES:
		var capture_size: Vector2i = capture["size"]
		root.content_scale_size = Vector2i.ZERO
		root.size = capture_size
		DisplayServer.window_set_size(capture_size)
		await process_frame
		await process_frame
		var image: Image = root.get_texture().get_image()
		var suffix: String = "_authoring" if is_authoring else ""
		var path: String = output_directory.path_join("%s%s.png" % [
			capture["name"],
			suffix,
		])
		var save_error: Error = image.save_png(path)
		if save_error != OK:
			push_error("VISUAL CHECK FAIL: could not save %s" % path)
			main.queue_free()
			quit(1)
			return
		print("VISUAL CHECK CAPTURE: %s (%dx%d)" % [
			path,
			image.get_width(),
			image.get_height(),
		])

	main.queue_free()
	await process_frame
	print("VISUAL CHECK PASS: defense inspection captures created")
	quit(0)


func _output_directory(arguments: PackedStringArray) -> String:
	for index: int in arguments.size():
		if arguments[index] == "--output-dir" and index + 1 < arguments.size():
			return arguments[index + 1]
	return "res://build/visual_checks/m3_1"


func _is_authoring(arguments: PackedStringArray) -> bool:
	return arguments.has("--authoring")
