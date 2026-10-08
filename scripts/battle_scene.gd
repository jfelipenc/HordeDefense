extends Node
## The battle screen: builds the Battle, the 3D view, the HUD and the regroup screen, ticks the
## battle every frame, forwards its signals to EventBus and shows the result. This is the only
## battle script that names autoloads (class scripts cannot, see Battle).

var battle: Battle
var view: BattleView
var hud: BattleHud
var regroup: RegroupScreen
var result_label: Label
var result_panel: PanelContainer
var reward_gold: int = 0

func _ready() -> void:
	battle = BattleFactory.create(GameState.march_capacity)
	view = BattleView.new()
	view.battle = battle
	add_child(view)
	hud = BattleHud.new()
	hud.battle = battle
	add_child(hud)
	regroup = RegroupScreen.new()
	regroup.battle = battle
	add_child(regroup)
	_build_result_panel()
	_forward_signals()
	battle.phase.regroup_started.connect(func(_p): regroup.open())
	battle.phase.wave_started.connect(func(_w): regroup.close())
	battle.phase.battle_ended.connect(_on_battle_ended)
	EventBus.debug_spawn_wave.connect(battle.debug_jump_to_wave)
	EventBus.debug_skip_phase.connect(battle.debug_skip_phase)
	battle.start()

func _process(delta: float) -> void:
	# If the regroup countdown is about to run out, apply the player's choices first so the
	# timeout starts the wave with them instead of discarding them.
	if battle.in_regroup() and regroup.visible and battle.phase.timer <= delta:
		regroup.press_ready()
	battle.tick(delta)

func _exit_tree() -> void:
	EventBus.debug_spawn_wave.disconnect(battle.debug_jump_to_wave)
	EventBus.debug_skip_phase.disconnect(battle.debug_skip_phase)

func _forward_signals() -> void:
	battle.enemy_killed.connect(EventBus.enemy_killed.emit)
	battle.wall_damaged.connect(EventBus.wall_damaged.emit)
	battle.phase.wave_started.connect(EventBus.wave_started.emit)
	battle.phase.wave_cleared.connect(EventBus.wave_cleared.emit)
	battle.phase.phase_cleared.connect(EventBus.phase_cleared.emit)
	battle.phase.regroup_started.connect(EventBus.regroup_started.emit)
	battle.phase.battle_ended.connect(EventBus.battle_ended.emit)

func _on_battle_ended(victory: bool) -> void:
	var before := GameState.gold
	GameState.record_battle(victory, battle.phase.highest_wave)
	reward_gold = GameState.gold - before
	result_label.text = "%s\nReached wave %d\n+%d gold" % ["VICTORY" if victory else "DEFEAT", battle.phase.highest_wave, reward_gold]
	result_panel.visible = true

func play_again() -> void:
	SceneSwapper.swap_to("res://scenes/Battle.tscn")

func _build_result_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	result_panel.visible = false
	layer.add_child(result_panel)
	var box := VBoxContainer.new()
	result_panel.add_child(box)
	result_label = Label.new()
	result_label.add_theme_font_size_override("font_size", 64)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_label)
	var again := Button.new()
	again.text = "Defend again"
	again.add_theme_font_size_override("font_size", 56)
	again.custom_minimum_size = Vector2(500, 120)
	again.pressed.connect(play_again)
	box.add_child(again)
