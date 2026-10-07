extends RefCounted

var t

func test_swap_replaces_current_scene() -> void:
	var sw = t.root.get_node("SceneSwapper")
	await sw.swap_to("res://scenes/debug/placeholder_a.tscn", 0.05)
	t.eq(sw.current.name, &"PlaceholderA", "first scene shown")
	var first = sw.current
	await sw.swap_to("res://scenes/debug/placeholder_b.tscn", 0.05)
	t.eq(sw.current.name, &"PlaceholderB", "second scene shown")
	await t.process_frame
	t.check(not is_instance_valid(first), "previous scene freed")

func test_swap_fades_to_black_and_back() -> void:
	var sw = t.root.get_node("SceneSwapper")
	var peak := [0.0]
	var cb := func(a): peak[0] = maxf(peak[0], a)
	sw.fade_changed.connect(cb)
	await sw.swap_to("res://scenes/debug/placeholder_a.tscn", 0.1)
	sw.fade_changed.disconnect(cb)
	t.eq(peak[0], 1.0, "screen fully black at the swap point")
	t.eq(sw.fade_alpha(), 0.0, "fade finished clear")

func test_swap_with_zero_duration_is_instant_but_valid() -> void:
	var sw = t.root.get_node("SceneSwapper")
	await sw.swap_to("res://scenes/debug/placeholder_b.tscn", 0.0)
	t.eq(sw.current.name, &"PlaceholderB", "instant swap")
