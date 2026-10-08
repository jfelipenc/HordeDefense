extends SceneTree
## Saves two screenshots of the battle screen: godot --path . -s res://tools/screenshot.gd -- <out_dir>
## (needs a window, so it cannot run with --headless).

func _initialize() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "."
	var scene := (load("res://scenes/Battle.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await create_timer(0.5).timeout
	_save(out + "/regroup.png")
	scene.regroup.set_tower_choice(0, 0, 1)
	scene.regroup.set_tower_choice(2, 1, 3)
	scene.regroup.press_ready()
	scene.battle.debug_jump_to_wave(12)
	await create_timer(4.0).timeout
	_save(out + "/wave12.png")
	quit()

func _save(path: String) -> void:
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
