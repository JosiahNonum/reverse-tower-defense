extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://src/presentation/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("SMOKE FAIL: main scene could not be loaded")
		quit(1)
		return

	var scene_instance: Node = packed_scene.instantiate()
	if scene_instance.name != "Main":
		push_error("SMOKE FAIL: expected the root node to be named Main")
		scene_instance.free()
		quit(1)
		return

	scene_instance.free()
	print("SMOKE PASS: main scene loads and instantiates")
	quit(0)
