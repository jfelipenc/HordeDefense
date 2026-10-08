extends RefCounted

var t

func _view(b: Battle) -> BattleView:
	var v := BattleView.new()
	v.battle = b
	t.root.add_child(v)
	return v

func test_view_without_a_battle_does_not_crash() -> void:
	var v := BattleView.new()
	t.root.add_child(v)
	await t.process_frame
	v.refresh()
	t.eq(v.visible_enemy_count(), 0, "nothing to draw")
	v.queue_free()

func test_enemy_instances_follow_the_horde() -> void:
	var b := BattleFactory.create(1500)
	b.start()
	b.ready()
	var v := _view(b)
	for _i in 30:
		b.tick(0.1)
	v.refresh()
	t.check(b.horde.count() > 0, "enemies exist")
	t.eq(v.visible_enemy_count(), mini(b.horde.count(), BattleView.MAX_ENEMIES), "one instance per enemy")
	v.queue_free()

func test_enemy_instances_are_capped() -> void:
	var b := BattleFactory.create(100)
	var v := _view(b)
	for i in 700:
		b.horde.spawn(load("res://resources/enemies/raider.tres"), i % 3, 20.0, 1.0)
	v.refresh()
	t.eq(v.visible_enemy_count(), 500, "no more than 500 drawn")
	t.eq(b.horde.count(), 700, "but all 700 still exist")
	v.queue_free()

func test_wall_color_tracks_the_crack_stage() -> void:
	var b := BattleFactory.create(0, null, "")
	var v := _view(b)
	v.refresh()
	var fresh := v.wall_color(1)
	t.eq(fresh, BattleView.WALL_COLORS[0], "fresh wall")
	b.state.damage_wall(1, b.state.wall_max[1] * 0.5)
	v.refresh()
	t.eq(v.wall_color(1), BattleView.WALL_COLORS[1], "scuffed at half health")
	b.state.damage_wall(1, 99999.0)
	v.refresh()
	t.eq(v.wall_color(1), BattleView.WALL_COLORS[3], "broken")
	t.eq(v.wall_color(0), fresh, "other walls unaffected")
	v.queue_free()

func test_troop_models_and_label_follow_the_pool() -> void:
	var b := BattleFactory.create(1500)
	var v := _view(b)
	v.refresh()
	t.eq(v.troop_label(0), "I 250  C 100  A 150", "label shows the real numbers")
	t.eq(v.troop_model_count(0), 5, "500 troops = 5 stand-in models at 100 each")
	b.state.pool.take_losses(0, UnitRole.Kind.INFANTRY, 250)
	v.refresh()
	t.eq(v.troop_label(0), "I 0  C 100  A 150", "losses show up")
	t.eq(v.troop_model_count(0), 3, "250 troops = 3 models")
	v.queue_free()

func test_empty_section_draws_no_models() -> void:
	var b := BattleFactory.create(0, null, "")
	var v := _view(b)
	v.refresh()
	t.eq(v.troop_model_count(2), 0, "nobody there")
	v.queue_free()

func test_huge_armies_cap_their_models() -> void:
	var b := BattleFactory.create(30000)
	var v := _view(b)
	v.refresh()
	t.eq(v.troop_model_count(1), BattleView.MAX_TROOP_MODELS, "model count capped")
	v.queue_free()

func test_tower_markers_show_only_occupied_slots() -> void:
	var b := BattleFactory.create(100)
	b.start()
	var v := _view(b)
	v.refresh()
	t.check(not v.tower_visible(1, 0), "empty slot hidden")
	b.set_tower(1, 0, load("res://resources/towers/arrow_tower.tres"))
	v.refresh()
	t.check(v.tower_visible(1, 0), "occupied slot shown")
	t.check(not v.tower_visible(1, 1), "its neighbour still hidden")
	v.queue_free()
