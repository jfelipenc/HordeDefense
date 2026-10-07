extends Node
## Placeholder scene swapper: gate run -> wall placeholder -> back to a new gate run.

const WALL_SCENE := preload("res://scenes/WallPlaceholder.tscn")

var current_run: GateRun
var wall: Node

func _ready() -> void:
	EventBus.gate_run_finished.connect(_on_gate_run_finished)
	start_run()

func start_run() -> void:
	_clear()
	current_run = GateRun.new()
	add_child(current_run)

func _on_gate_run_finished(count: int, buffs: Dictionary, composition: Dictionary) -> void:
	_clear()
	wall = WALL_SCENE.instantiate()
	add_child(wall)
	wall.show_result(count, buffs, composition, GameState.gold)
	wall.restart_requested.connect(start_run)

func _clear() -> void:
	if current_run:
		current_run.queue_free()
		current_run = null
	if wall:
		wall.queue_free()
		wall = null
