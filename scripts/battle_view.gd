class_name BattleView
extends Node3D
## Grey-box 3D battlefield: three lanes running away from the camera, the wall at z=0, the Town
## Center behind it. Enemies are one MultiMesh; troops are one small MultiMesh per section.
## Reads the Battle every frame and never changes it.

const LANE_X := [-6.0, 0.0, 6.0]
const MAX_ENEMIES := 500
const TROOPS_PER_MODEL := 100
const MAX_TROOP_MODELS := 12
const WALL_COLORS := [Color(0.62, 0.52, 0.4), Color(0.58, 0.42, 0.3), Color(0.45, 0.3, 0.22), Color(0.2, 0.15, 0.12)]
const ROLE_COLORS := {
	UnitRole.Kind.INFANTRY: Color(0.85, 0.25, 0.25),
	UnitRole.Kind.CAVALRY: Color(0.9, 0.55, 0.15),
	UnitRole.Kind.ARCHERS: Color(0.7, 0.3, 0.8),
	UnitRole.Kind.NONE: Color(0.25, 0.1, 0.1),
}

var battle: Battle

var _enemies: MultiMeshInstance3D
var _walls: Array[MeshInstance3D] = []
var _wall_materials: Array[StandardMaterial3D] = []
var _troop_meshes: Array[MultiMeshInstance3D] = []
var _troop_labels: Array[Label3D] = []
var _tower_boxes: Array = [[], [], []]
var _town_center: MeshInstance3D

func _ready() -> void:
	_build_world()
	refresh()

func _process(_delta: float) -> void:
	refresh()

## Number of enemy instances currently drawn (capped at MAX_ENEMIES).
func visible_enemy_count() -> int:
	return _enemies.multimesh.visible_instance_count

func wall_color(section: int) -> Color:
	return _wall_materials[section].albedo_color

func troop_model_count(section: int) -> int:
	return _troop_meshes[section].multimesh.visible_instance_count

func troop_label(section: int) -> String:
	return _troop_labels[section].text

func tower_visible(section: int, slot: int) -> bool:
	return _tower_boxes[section][slot].visible

func refresh() -> void:
	if battle == null:
		return
	_refresh_enemies()
	_refresh_walls()
	_refresh_troops()
	_refresh_towers()

# --- building ---------------------------------------------------------------

func _build_world() -> void:
	var cam := Camera3D.new()
	# Portrait is narrow, so the field of view is fixed to the width: all three lanes and both
	# flank edges stay on screen, with the spawn edge at the top and the Town Center at the bottom.
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 50.0
	cam.position = Vector3(0, 28, 5)
	cam.rotation_degrees = Vector3(-65, 0, 0)
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 70)
	ground.mesh = plane
	ground.position = Vector3(0, 0, -14)
	ground.material_override = _flat(Color(0.35, 0.5, 0.3))
	add_child(ground)
	_town_center = _box(Vector3(5, 3, 3), Color(0.25, 0.4, 0.8), Vector3(0, 1.5, 6.5))
	for s in 3:
		var wall := _box(Vector3(5.2, 2.4, 1.0), Color.WHITE, Vector3(LANE_X[s], 1.2, 0))
		_walls.append(wall)
		_wall_materials.append(wall.material_override)
		_troop_meshes.append(_troop_multimesh(s))
		var label := Label3D.new()
		label.position = Vector3(LANE_X[s], 3.6, 1.5)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.012
		label.font_size = 48
		label.outline_size = 12
		add_child(label)
		_troop_labels.append(label)
		for slot in 2:
			var tower := _box(Vector3(0.9, 1.4, 0.9), Color(0.9, 0.85, 0.3), Vector3(LANE_X[s] - 1.5 + slot * 3.0, 3.0, 0))
			tower.visible = false
			_tower_boxes[s].append(tower)
	_enemies = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var body := BoxMesh.new()
	body.size = Vector3(0.8, 1.2, 0.8)
	mm.mesh = body
	mm.instance_count = MAX_ENEMIES
	mm.visible_instance_count = 0
	_enemies.multimesh = mm
	_enemies.material_override = _flat(Color.WHITE, true)
	add_child(_enemies)

func _troop_multimesh(section: int) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var body := CapsuleMesh.new()
	body.radius = 0.35
	body.height = 1.2
	mm.mesh = body
	mm.instance_count = MAX_TROOP_MODELS
	mm.visible_instance_count = 0
	node.multimesh = mm
	node.material_override = _flat(Color.WHITE, true)
	add_child(node)
	return node

func _box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _flat(color)
	node.position = pos
	add_child(node)
	return node

func _flat(color: Color, vertex_colors: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.vertex_color_use_as_albedo = vertex_colors
	return m

# --- per-frame updates --------------------------------------------------------

func _refresh_enemies() -> void:
	var h := battle.horde
	var n := mini(h.count(), MAX_ENEMIES)
	var mm := _enemies.multimesh
	for i in n:
		var e := h.types[i]
		# Spread each lane's enemies sideways so a horde reads as a mass, not a queue.
		var x: float = LANE_X[h.lane[i]] + (fposmod(i * 0.618034, 1.0) - 0.5) * 4.0
		if h.from_side[i] == 1:
			x += 8.0 * (h.dist[i] / battle.tuning.lane_length) * (-1.0 if h.lane[i] == 0 else 1.0)
		var basis := Basis().scaled(Vector3.ONE * e.model_scale)
		mm.set_instance_transform(i, Transform3D(basis, Vector3(x, 0.6 * e.model_scale, -h.dist[i])))
		mm.set_instance_color(i, ROLE_COLORS[e.role])
	mm.visible_instance_count = n

func _refresh_walls() -> void:
	for s in 3:
		_wall_materials[s].albedo_color = WALL_COLORS[battle.state.crack_stage(s)]

func _refresh_troops() -> void:
	var pool := battle.state.pool
	for s in 3:
		var total := pool.section_total(s)
		var models := mini(ceili(float(total) / TROOPS_PER_MODEL), MAX_TROOP_MODELS)
		var mm := _troop_meshes[s].multimesh
		for i in models:
			var kind := _kind_for_model(s, i, models)
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(LANE_X[s] - 2.0 + (i % 6) * 0.8, 0.6, 1.8 + (i / 6) * 1.0)))
			mm.set_instance_color(i, battle.state.troop_defs[kind].color)
		mm.visible_instance_count = models
		_troop_labels[s].text = "I %d  C %d  A %d" % [pool.count(s, UnitRole.Kind.INFANTRY), pool.count(s, UnitRole.Kind.CAVALRY), pool.count(s, UnitRole.Kind.ARCHERS)]

## Model i of n in a section stands in for whichever kind owns that share of the section's troops.
func _kind_for_model(section: int, i: int, n: int) -> int:
	var total := battle.state.pool.section_total(section)
	if total <= 0:
		return UnitRole.Kind.INFANTRY
	var at := (float(i) + 0.5) / float(n) * total
	var running := 0.0
	for k in UnitRole.TROOP_KINDS:
		running += battle.state.pool.count(section, k)
		if at <= running:
			return k
	return UnitRole.Kind.ARCHERS

func _refresh_towers() -> void:
	for s in 3:
		for slot in 2:
			_tower_boxes[s][slot].visible = battle.state.towers[s][slot] != null
