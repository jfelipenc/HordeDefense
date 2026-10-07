extends RefCounted

var t

func test_enemy_example_loads_with_core_fields() -> void:
	var e := load("res://resources/enemies/grunt.tres") as EnemyData
	t.check(e != null, "grunt.tres loads as EnemyData")
	if e:
		t.check(e.hp > 0 and e.speed > 0 and e.cost > 0, "grunt has hp, speed, cost")
		t.eq(e.id, &"grunt", "grunt id")

func test_unit_example_loads_with_core_fields() -> void:
	var u := load("res://resources/units/soldier.tres") as UnitData
	t.check(u != null, "soldier.tres loads as UnitData")
	if u:
		t.check(u.hp > 0 and u.damage > 0, "soldier has hp and damage")
		t.eq(u.id, &"soldier", "soldier id")

func test_card_example_loads_with_core_fields() -> void:
	var c := load("res://resources/cards/repair_wall.tres") as CardData
	t.check(c != null, "repair_wall.tres loads as CardData")
	if c:
		t.check(c.title != "" and c.description != "", "card has text")

func test_hero_example_loads_with_core_fields() -> void:
	var h := load("res://resources/heroes/knight_captain.tres") as HeroData
	t.check(h != null, "knight_captain.tres loads as HeroData")
	if h:
		t.check(h.skill_cooldown >= 8.0 and h.skill_cooldown <= 20.0, "cooldown within design range 8-20 s")

func test_section_data_has_wave_fields() -> void:
	var s := SectionData.new()
	t.check("region" in s and "section_index" in s and "allowed_enemies" in s, "section fields for the wave spawner")
	t.eq(s.section_index, 0, "default index")
