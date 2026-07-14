extends Node

const GameStateScript := preload("res://scripts/core/game_state.gd")

enum RoundState { WAITING, ROLE_ASSIGNMENT, HIDING, SEARCHING, RESULTS, RESTARTING }

signal phase_changed(phase_name: String, seconds_left: int)
signal timer_changed(seconds_left: int)
signal round_message(message: String)
signal round_finished(winner: String)
signal hider_count_changed(remaining: int, total: int)
signal role_counts_changed(hiders: int, seekers: int)
signal state_changed(state: RoundState)
signal roles_assigned

@export var waiting_time := 3
@export var role_assignment_time := 2
@export var hiding_time := 18
@export var seeking_time := 45
@export var results_time := 6
@export var restarting_time := 2
@export_enum("Infection", "Classic") var round_mode := "Infection"
@export var allow_shadow_toggle := true

@onready var timer: Timer = $Timer
@onready var player: CharacterBody3D = $"../Player"
@onready var hider_spawn: Marker3D = $"../Spawns/HiderSpawn"
@onready var seeker_spawn: Marker3D = $"../Spawns/SeekerSpawn"

var seconds_left := 0
var state: RoundState = RoundState.WAITING
var phase_name := "Waiting"
var hiders: Array = []
var seekers: Array = []
var total_hiders := 0
var remaining_hiders := 0
var round_number := 0
var _started := false

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	call_deferred("start_round")

func set_hiders(next_hiders: Array) -> void:
	hiders = next_hiders
	total_hiders = hiders.size()
	remaining_hiders = total_hiders
	for hider in hiders:
		if hider.has_signal("found") and not hider.found.is_connected(_on_hider_found):
				hider.found.connect(_on_hider_found)
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_emit_role_counts()

func set_seekers(next_seekers: Array) -> void:
	seekers = next_seekers
	_emit_role_counts()

func start_round() -> void:
	if not is_inside_tree():
		return
	_started = true
	round_number += 1
	_reset_players()
	_refresh_hider_count()
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_emit_role_counts()
	_set_state(RoundState.WAITING, waiting_time, "Wachten op spelers")

func restart_round() -> void:
	start_round()

func register_scan(found: bool, target: Node = null, _energy: float = 0.0) -> void:
	if state != RoundState.SEARCHING:
		round_message.emit("Wacht tot de seekerfase")
		return
	if not found or not target or not is_instance_valid(target):
		round_message.emit("Scan mis")
		return
	if target.has_method("is_hidden_alive") and not target.is_hidden_alive():
		round_message.emit("Doel is al besmet")
		return
	if round_mode == "Infection" and target.has_method("convert_to_seeker"):
		target.convert_to_seeker()
	else:
		if target.has_method("mark_found"):
			target.mark_found()
	_refresh_hider_count()
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_emit_role_counts()
	round_message.emit("Treffer bevestigd - %s" % ("besmet" if round_mode == "Infection" else "gevonden"))
	if remaining_hiders <= 0:
		_finish_round("SEEKER")

func _on_timer_timeout() -> void:
	seconds_left -= 1
	timer_changed.emit(seconds_left)
	if seconds_left > 0:
		return
	match state:
		RoundState.WAITING:
			_set_state(RoundState.ROLE_ASSIGNMENT, role_assignment_time, "Rollen worden verdeeld")
		RoundState.ROLE_ASSIGNMENT:
			_assign_roles()
			_set_state(RoundState.HIDING, hiding_time, "Verstopfase - zoek een goede plek")
		RoundState.HIDING:
			if player.has_method("set_hider"):
				player.set_hider(false)
			if player.has_method("set_round_input_locked"):
				player.set_round_input_locked(false)
			_set_state(RoundState.SEARCHING, seeking_time, "Zoekfase - scan verdachte plekken")
		RoundState.SEARCHING:
			_finish_round("HIDER")
		RoundState.RESULTS:
			_set_state(RoundState.RESTARTING, restarting_time, "Nieuwe ronde wordt voorbereid")
		RoundState.RESTARTING:
			start_round()

func _finish_round(winner: String) -> void:
	_set_state(RoundState.RESULTS, results_time, "%s wint de ronde" % winner)
	var history := get_node_or_null("/root/SessionHistoryService")
	if history and player:
		var role := "Hider" if player.is_hider else "Seeker"
		var result := "Gewonnen" if (role == "Hider" and winner == "HIDER") or (role == "Seeker" and winner == "SEEKER") else "Verloren"
		history.record_round(round_mode, role, result, 275 if result == "Gewonnen" else 90)
	round_finished.emit(winner)

func _set_state(new_state: RoundState, duration: int, message: String) -> void:
	state = new_state
	seconds_left = duration
	phase_name = _state_name()
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_state(_game_state_for_round_state())
	state_changed.emit(state)
	for seeker in seekers:
		if is_instance_valid(seeker) and seeker.has_method("set_search_enabled"):
			seeker.set_search_enabled(new_state == RoundState.SEARCHING)
	phase_changed.emit(phase_name, seconds_left)
	timer_changed.emit(seconds_left)
	round_message.emit(message)
	if duration > 0:
		timer.start(duration)

func _phase_name() -> String:
	return phase_name

func _state_name() -> String:
	match state:
		RoundState.WAITING:
			return "Waiting"
		RoundState.ROLE_ASSIGNMENT:
			return "Role Assignment"
		RoundState.HIDING:
			return "Hiding"
		RoundState.SEARCHING:
			return "Seeking"
		RoundState.RESULTS:
			return "Round Results"
		RoundState.RESTARTING:
			return "Restarting"
		_:
			return "Training"

func _game_state_for_round_state() -> GameStateScript.State:
	match state:
		RoundState.WAITING:
			return GameStateScript.State.WAITING
		RoundState.ROLE_ASSIGNMENT:
			return GameStateScript.State.ROLE_ASSIGNMENT
		RoundState.HIDING:
			return GameStateScript.State.HIDING
		RoundState.SEARCHING:
			return GameStateScript.State.SEEKING
		RoundState.RESULTS:
			return GameStateScript.State.ROUND_RESULTS
		RoundState.RESTARTING:
			return GameStateScript.State.RESTARTING
		_:
			return GameStateScript.State.PREPARATION

func _assign_roles() -> void:
	if player.has_method("set_hider"):
		player.set_hider(true)
	if player.has_method("set_shadow_policy"):
		player.set_shadow_policy(allow_shadow_toggle)
	if player.has_method("set_round_input_locked"):
		player.set_round_input_locked(true)
	roles_assigned.emit()

func _reset_players() -> void:
	if player.has_method("reset_to_spawn"):
		player.reset_to_spawn(hider_spawn.global_transform, true)
	for hider in hiders:
		if is_instance_valid(hider):
			if hider.has_method("reset_for_round"):
				hider.reset_for_round()
			else:
				hider.visible = true
				hider.set_collision_layer_value(1, true)
				hider.set_collision_mask_value(1, true)
	for seeker in seekers:
		if is_instance_valid(seeker) and seeker.has_method("reset_for_round"):
			seeker.reset_for_round()

func _refresh_hider_count() -> void:
	remaining_hiders = 0
	for hider in hiders:
		if is_instance_valid(hider) and hider.has_method("is_hidden_alive") and hider.is_hidden_alive():
			remaining_hiders += 1

func _emit_role_counts() -> void:
	var seeker_count := get_tree().get_nodes_in_group("seekers").size()
	if player and is_instance_valid(player) and not player.is_hider:
		seeker_count += 1 if not player.is_in_group("seekers") else 0
	role_counts_changed.emit(remaining_hiders, seeker_count)

func _on_hider_found(_hider: Node) -> void:
	_refresh_hider_count()
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_emit_role_counts()
	if state == RoundState.SEARCHING and remaining_hiders <= 0:
		_finish_round("SEEKER")
