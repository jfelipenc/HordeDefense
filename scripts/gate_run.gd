class_name GateRun
extends Node3D
## The gate run: auto-runs the squad along a road built from a SectionData,
## resolves gate pairs and blockers in order, then hands the squad off via EventBus.

const GATE_SCENE := preload("res://scenes/Gate.tscn")

@export var section: SectionData
@export var speed: float = 10.0
## World units of steering per screen pixel of drag.
@export var drag_sensitivity: float = 0.012
@export var steer_rate: float = 12.0
@export var keyboard_speed: float = 8.0

var squad: Squad
var distance: float = 0.0

var _steer_target: float = 0.0
var _events: Array = []
var _next: int = 0
var _fight_left: float = 0.0
var _fighting: bool = false
var _finished: bool = false
var _gate_views: Array[GateView] = []
var _blocker_enemies: Array[MeshInstance3D] = []
var _rig: Node3D

func _ready() -> void:
	if section == null:
		section = load("res://resources/sections/section_test.tres")
	_build_level()
	_build_events()
	squad = Squad.new()
	add_child(squad)
	squad.setup(SquadState.new({"soldier": GameState.base_squad_size}))
	_place_squad()

# -- public API -------------------------------------------------------------

func is_finished() -> bool:
	return _finished

func is_fighting() -> bool:
	return _fighting

func gate_view_count() -> int:
	return _gate_views.size()

func blocker_enemy_count() -> int:
	return _blocker_enemies.size()

func steer_target() -> float:
	return _steer_target

func max_x() -> float:
	return section.road_width * 0.5 - 0.6

func set_steer(x: float) -> void:
	_steer_target = clampf(x, -max_x(), max_x())

func snap_steer(x: float) -> void:
	set_steer(x)
	squad.position.x = _steer_target

func step(delta: float) -> void:
	if _finished:
		return
	squad.position.x = lerpf(squad.position.x, _steer_target, 1.0 - exp(-steer_rate * delta))
	var remaining := delta
	while remaining > 0.0 and not _finished:
		if _fighting:
			var spent := minf(remaining, _fight_left)
			_fight_left -= spent
			remaining -= spent
			if _fight_left <= 0.0:
				_end_fight()
			continue
		var ev: Dictionary = _events[_next]
		var gap: float = ev.distance - distance
		var move := speed * remaining
		if move < gap:
			distance += move
			remaining = 0.0
		else:
			distance = ev.distance
			remaining -= gap / speed
			_process_event(ev)
	_place_squad()

# -- input ------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		set_steer(_steer_target + event.relative.x * drag_sensitivity)

func _process(delta: float) -> void:
	var axis := Input.get_axis("ui_left", "ui_right")
	if axis != 0.0:
		set_steer(_steer_target + axis * keyboard_speed * delta)
	step(delta)

# -- events -----------------------------------------------------------------

func _build_events() -> void:
	_events.clear()
	for p in section.gate_pairs:
		_events.append({"distance": p.distance, "kind": "pair", "data": p})
	for b in section.blockers:
		_events.append({"distance": b.distance, "kind": "blocker", "data": b})
	_events.append({"distance": section.road_length, "kind": "end", "data": null})
	_events.sort_custom(func(a, b): return a.distance < b.distance)

func _process_event(ev: Dictionary) -> void:
	match ev.kind:
		"pair":
			var gate: GateData = ev.data.pick(squad.position.x)
			var overflow := squad.apply_gate(gate, GameState.barracks_cap)
			if overflow > 0:
				GameState.add_gold(overflow)
			EventBus.gate_passed.emit(gate)
			_next += 1
		"blocker":
			_fighting = true
			_fight_left = ev.data.fight_time
			if _fight_left <= 0.0:
				_end_fight()
		"end":
			_finished = true
			EventBus.gate_run_finished.emit(squad.state.total(), squad.state.buffs.duplicate(), squad.state.counts.duplicate())

func _end_fight() -> void:
	var ev: Dictionary = _events[_next]
	squad.lose(ev.data.losses)
	for e in _blocker_enemies:
		e.queue_free()
	_blocker_enemies.clear()
	_fighting = false
	_next += 1

func _place_squad() -> void:
	squad.position.z = -distance
	if _rig:
		_rig.position.z = -distance

# -- level building ---------------------------------------------------------

func _build_level() -> void:
	var width := section.road_width
	var road := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(width, 0.2, section.road_length + 40.0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.45, 0.42, 0.38)
	rbox.material = rmat
	road.mesh = rbox
	road.position = Vector3(0, -0.1, -section.road_length * 0.5 + 10.0)
	add_child(road)

	var finish := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(width, 0.05, 0.6)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1, 1, 1)
	fbox.material = fmat
	finish.mesh = fbox
	finish.position = Vector3(0, 0.03, -section.road_length)
	add_child(finish)

	for p in section.gate_pairs:
		_add_gate(p.left, Vector3(-width * 0.25, 0, -p.distance), width * 0.5)
		_add_gate(p.right, Vector3(width * 0.25, 0, -p.distance), width * 0.5)
	for b in section.blockers:
		_add_blocker(b)

	_rig = Node3D.new()
	add_child(_rig)
	var cam := Camera3D.new()
	_rig.add_child(cam)
	cam.position = Vector3(0, 11.0, 10.0)
	cam.rotation_degrees = Vector3(-42.0, 0, 0)
	cam.fov = 60.0
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	add_child(sun)

func _add_gate(gate: GateData, pos: Vector3, width: float) -> void:
	var view: GateView = GATE_SCENE.instantiate()
	view.position = pos
	add_child(view)
	view.build(gate, width)
	_gate_views.append(view)

func _add_blocker(b: BlockerData) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.22
	mesh.height = 1.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.2, 0.2)
	mesh.material = mat
	var slots := Formation.slots(b.enemy_count, Squad.SPACING)
	for s in slots:
		var e := MeshInstance3D.new()
		e.mesh = mesh
		e.position = Vector3(s.x, Squad.HALF_HEIGHT, -b.distance - 3.0 + s.y)
		add_child(e)
		_blocker_enemies.append(e)
