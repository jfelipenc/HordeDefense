extends TestCase

const MAIN := "res://scenes/Main.tscn"
const A := "res://scenes/placeholder_a.tscn"
const B := "res://scenes/placeholder_b.tscn"


func _root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


func _spawn_main() -> Node:
	var main: Node = (load(MAIN) as PackedScene).instantiate()
	main.fade_time = 0.01
	main.start_scene = ""
	_root().add_child(main)
	return main


func test_main_is_project_main_scene() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), MAIN, "main_scene")


func test_swap_between_two_placeholder_scenes() -> void:
	var main := _spawn_main()
	await main.swap_to(A)
	assert_eq(main.current_scene_path, A, "after first swap path")
	assert_eq(main.current_scene.name, "PlaceholderA", "first scene node")
	await main.swap_to(B)
	assert_eq(main.current_scene.name, "PlaceholderB", "second scene node")
	assert_true(not is_instance_valid(main.get_node_or_null("SceneHolder/PlaceholderA")), "old scene freed")
	main.queue_free()


func test_fade_overlay_is_clear_after_swap() -> void:
	var main := _spawn_main()
	await main.swap_to(A)
	assert_eq(main.fade_alpha(), 0.0, "fade alpha after swap")
	main.queue_free()
