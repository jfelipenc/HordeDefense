extends Node
## Entry scene: hands over to the battle screen.

func _ready() -> void:
	SceneSwapper.swap_to("res://scenes/Battle.tscn", 0.0)
