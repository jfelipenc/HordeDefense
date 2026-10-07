extends TestCase

const CASES := {
	"res://scripts/data/section_data.gd": "res://resources/sections/section_example.tres",
	"res://scripts/data/enemy_data.gd": "res://resources/enemies/enemy_example.tres",
	"res://scripts/data/unit_data.gd": "res://resources/units/unit_example.tres",
	"res://scripts/data/gate_data.gd": "res://resources/gates/gate_example.tres",
	"res://scripts/data/card_data.gd": "res://resources/cards/card_example.tres",
	"res://scripts/data/hero_data.gd": "res://resources/heroes/hero_example.tres",
}


func _example(script_path: String) -> Resource:
	return load(CASES[script_path]) as Resource


func test_every_class_has_an_editable_example_resource() -> void:
	for script_path in CASES:
		var res := _example(script_path)
		assert_true(res != null, "cannot load %s" % CASES[script_path])
		if res != null:
			assert_eq(res.get_script().resource_path, script_path, "script of " + CASES[script_path])


func test_enemy_example_fields() -> void:
	var e := _example("res://scripts/data/enemy_data.gd")
	assert_eq(e.id, &"grunt", "id")
	assert_eq(e.cost, 1, "cost")
	assert_eq(e.first_section, 0, "first_section")
	assert_true(e.hp > 0.0 and e.speed > 0.0 and e.wall_damage > 0.0, "positive stats")


func test_section_example_fields() -> void:
	var s := _example("res://scripts/data/section_data.gd")
	assert_eq(s.index, 0, "index")
	assert_eq(s.base_budget, 100.0, "B0")
	assert_eq(s.allowed_enemies.size(), 1, "allowed enemies")
	assert_eq(s.allowed_enemies[0].id, &"grunt", "allowed enemy is grunt")
	assert_true(s.gates_left.size() > 0 and s.gates_left.size() == s.gates_right.size(), "parallel gate pair lists")


func test_gate_types_cover_all_five() -> void:
	var g := _example("res://scripts/data/gate_data.gd")
	var names: Array = g.GateType.keys()
	for n in ["ADDITIVE", "MULTIPLIER", "NEGATIVE", "TYPE", "BUFF"]:
		assert_true(names.has(n), "GateType lacks %s" % n)
	assert_eq(g.type, g.GateType.ADDITIVE, "example type")
	assert_eq(g.value, 8.0, "example value")


func test_unit_card_hero_example_fields() -> void:
	var u := _example("res://scripts/data/unit_data.gd")
	assert_eq(u.id, &"soldier", "unit id")
	assert_true(u.hp > 0.0 and u.damage > 0.0, "unit stats")
	var c := _example("res://scripts/data/card_data.gd")
	assert_eq(c.id, &"repair_wall", "card id")
	assert_true(c.title != "" and c.description != "", "card text")
	var h := _example("res://scripts/data/hero_data.gd")
	assert_eq(h.id, &"knight_captain", "hero id")
	assert_true(h.skill_cooldown >= 8.0 and h.skill_cooldown <= 20.0, "cooldown in design range")
