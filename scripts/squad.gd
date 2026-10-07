class_name Squad
extends Node3D
## The player's squad: SquadState plus one capsule follower per unit in a sunflower formation.
## Animation is driven by step(delta) so it is deterministic and testable.

const SPACING := 0.6
const FOLLOW_RATE := 8.0
const GROW_RATE := 4.0
const DYING_TIME := 0.5
const HALF_HEIGHT := 0.6
const POP_TIME := 0.35
const POP_SCALE := 1.6
const TYPE_COLORS := {
	"soldier": Color(0.25, 0.5, 0.95),
	"archer": Color(0.3, 0.8, 0.35),
}

class Follower:
	var node: MeshInstance3D
	var type: String
	var scale_t: float = 0.0
	var age: float = 0.0  # dying only

var state: SquadState
var _followers: Array[Follower] = []
var _dying: Array[Follower] = []
var _label: Label3D
var _label_count: int = 0
var _pop_t: float = POP_TIME
var _meshes := {}

func _ready() -> void:
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 128
	_label.pixel_size = 0.01
	_label.outline_size = 24
	_label.no_depth_test = true
	_label.position = Vector3(0, 3.6, 0)
	add_child(_label)
	_update_label()

func setup(p_state: SquadState) -> void:
	state = p_state
	_reconcile(false)

## Applies a gate, clamps to the barracks cap and returns the overflow (units converted to gold).
func apply_gate(gate: GateData, cap: int) -> int:
	state.apply_gate(gate)
	var overflow := state.clamp_to_cap(cap)
	_reconcile(true)
	_pop_t = 0.0
	return overflow

func lose(n: int) -> void:
	state.lose(n)
	_reconcile(true)
	_pop_t = 0.0

func unit_count() -> int:
	return _followers.size()

func unit_count_of(type: String) -> int:
	var n := 0
	for f in _followers:
		if f.type == type:
			n += 1
	return n

func dying_count() -> int:
	return _dying.size()

func label_count() -> int:
	return _label_count

func follower_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for f in _followers:
		out.append(Vector2(f.node.position.x, f.node.position.z))
	return out

func min_follower_scale() -> float:
	var m := INF
	for f in _followers:
		m = minf(m, f.node.scale.x)
	return m

func _process(delta: float) -> void:
	step(delta)

func step(delta: float) -> void:
	var slots := Formation.slots(_followers.size(), SPACING)
	var follow := 1.0 - exp(-FOLLOW_RATE * delta)
	for i in _followers.size():
		var f := _followers[i]
		var target := Vector3(slots[i].x, HALF_HEIGHT, slots[i].y)
		f.node.position = f.node.position.lerp(target, follow)
		f.scale_t = minf(1.0, f.scale_t + GROW_RATE * delta)
		f.node.scale = Vector3.ONE * f.scale_t
	for f in _dying.duplicate():
		f.age += delta
		var k := clampf(f.age / DYING_TIME, 0.0, 1.0)
		f.node.scale = Vector3.ONE * (1.0 - k)
		f.node.position.y -= 3.0 * delta
		if k >= 1.0:
			_dying.erase(f)
			f.node.queue_free()
	_pop_t = minf(POP_TIME, _pop_t + delta)
	if _label:
		var p := _pop_t / POP_TIME
		_label.scale = Vector3.ONE * (1.0 + (POP_SCALE - 1.0) * sin(p * PI))

## Makes followers match state.counts: spawn missing ones, retire surplus from the back.
func _reconcile(animate: bool) -> void:
	for type in state.counts.keys():
		var want: int = state.counts[type]
		var have := unit_count_of(type)
		for i in range(have, want):
			_spawn(type, animate)
	for type in _types_present():
		var want: int = state.counts.get(type, 0)
		var have := unit_count_of(type)
		var surplus := have - want
		var idx := _followers.size() - 1
		while surplus > 0 and idx >= 0:
			if _followers[idx].type == type:
				_retire(idx)
				surplus -= 1
			idx -= 1
	_update_label()

func _types_present() -> Array:
	var seen := {}
	for f in _followers:
		seen[f.type] = true
	return seen.keys()

func _spawn(type: String, animate: bool) -> void:
	var f := Follower.new()
	f.type = type
	f.node = MeshInstance3D.new()
	f.node.mesh = _mesh_for(type)
	f.node.position = Vector3(0, HALF_HEIGHT, 0)  # fresh units fan out from the centre
	f.scale_t = 0.0 if animate else 1.0
	f.node.scale = Vector3.ONE * f.scale_t
	add_child(f.node)
	_followers.append(f)

func _retire(idx: int) -> void:
	var f := _followers[idx]
	_followers.remove_at(idx)
	_dying.append(f)

func _mesh_for(type: String) -> CapsuleMesh:
	if not _meshes.has(type):
		var m := CapsuleMesh.new()
		m.radius = 0.22
		m.height = 1.2
		var mat := StandardMaterial3D.new()
		mat.albedo_color = TYPE_COLORS.get(type, Color(0.8, 0.8, 0.8))
		m.material = mat
		_meshes[type] = m
	return _meshes[type]

func _update_label() -> void:
	_label_count = state.total() if state else 0
	if _label:
		_label.text = str(_label_count)
