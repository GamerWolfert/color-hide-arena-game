extends Node

const GameStateScript := preload("res://scripts/core/game_state.gd")

signal phase_changed(phase_name: String, seconds_left: int)
signal timer_changed(seconds_left: int)
signal round_message(message: String)
signal round_finished(winner: String)
signal hider_count_changed(remaining: int, total: int)

@export var preparation_time := 12
@export var hiding_time := 18
@export var seeking_time := 45

@onready var timer: Timer = $Timer
@onready var player: CharacterBody3D = $"../Player"
@onready var hider_spawn: Marker3D = $"../Spawns/HiderSpawn"
@onready var seeker_spawn: Marker3D = $"../Spawns/SeekerSpawn"

var seconds_left := 0
var phase := GameStateScript.State.PREPARATION
var seeker_found_hider := false
var hiders: Array = []
var total_hiders := 0
var remaining_hiders := 0

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	start_round()

func set_hiders(next_hiders: Array) -> void:
	hiders = next_hiders
	total_hiders = hiders.size()
	remaining_hiders = total_hiders
	for hider in hiders:
		if hider.has_signal("found") and not hider.found.is_connected(_on_hider_found):
			hider.found.connect(_on_hider_found)
	hider_count_changed.emit(remaining_hiders, total_hiders)

func start_round() -> void:
	seeker_found_hider = false
	_reset_players()
	remaining_hiders = total_hiders
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_set_phase(GameStateScript.State.PREPARATION, preparation_time, "Voorbereiding gestart")
	timer.start()

func restart_round() -> void:
	start_round()

func register_scan(found: bool, target: Node = null, _energy: float = 0.0) -> void:
	if phase != GameStateScript.State.SEEKING:
		round_message.emit("Wacht tot de seekerfase")
		return
	if found:
		seeker_found_hider = true
		if target and target.has_method("mark_found"):
			target.mark_found()
		round_message.emit("Treffer bevestigd")
		if remaining_hiders <= 0:
			_finish_round("SEEKER")
	else:
		round_message.emit("Scan mis")

func _on_timer_timeout() -> void:
	seconds_left -= 1
	timer_changed.emit(seconds_left)
	if seconds_left > 0:
		return
	match phase:
		GameStateScript.State.PREPARATION:
			_set_phase(GameStateScript.State.HIDING, hiding_time, "Verstopfase")
		GameStateScript.State.HIDING:
			if player.has_method("set_hider"):
				player.set_hider(false)
			_set_phase(GameStateScript.State.SEEKING, seeking_time, "Zoekfase")
		GameStateScript.State.SEEKING:
			_finish_round("HIDER")
		GameStateScript.State.ROUND_RESULTS:
			start_round()

func _finish_round(winner: String) -> void:
	_set_phase(GameStateScript.State.ROUND_RESULTS, 8, "%s wint" % winner)
	round_finished.emit(winner)

func _set_phase(new_phase: int, duration: int, message: String) -> void:
	phase = new_phase
	seconds_left = duration
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_state(new_phase)
	phase_changed.emit(_phase_name(), seconds_left)
	timer_changed.emit(seconds_left)
	round_message.emit(message)

func _phase_name() -> String:
	match phase:
		GameStateScript.State.PREPARATION:
			return "Preparation"
		GameStateScript.State.HIDING:
			return "Hiding"
		GameStateScript.State.SEEKING:
			return "Seeking"
		GameStateScript.State.ROUND_RESULTS:
			return "RoundResults"
		_:
			return "Training"

func _reset_players() -> void:
	if player.has_method("reset_to_spawn"):
		player.reset_to_spawn(hider_spawn.global_transform, true)
	for hider in hiders:
		if is_instance_valid(hider):
			hider.hidden_alive = true
			hider.visible = true
			hider.set_collision_layer_value(1, true)
			hider.set_collision_mask_value(1, true)

func _on_hider_found(_hider: Node) -> void:
	remaining_hiders = 0
	for hider in hiders:
		if is_instance_valid(hider) and hider.has_method("is_hidden_alive") and hider.is_hidden_alive():
			remaining_hiders += 1
	hider_count_changed.emit(remaining_hiders, total_hiders)
	if phase == GameStateScript.State.SEEKING and remaining_hiders <= 0:
		_finish_round("SEEKER")
