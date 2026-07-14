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
signal roster_changed

@export var waiting_time := 3
@export var role_assignment_time := 2
@export var hiding_time := 18
@export var seeking_time := 45
@export var results_time := 6
@export var restarting_time := 2
@export_enum("Infection", "Classic") var round_mode := "Infection"
@export var allow_shadow_toggle := true
@export_enum("Hider", "Seeker", "Random") var player_role := "Hider"

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
var network_authoritative := false

func _ready() -> void:
	timer.wait_time = 1.0
	timer.one_shot = false
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	var roster := _roster()
	if roster and not roster.roster_changed.is_connected(_on_roster_changed):
		roster.roster_changed.connect(_on_roster_changed)
	call_deferred("start_round")

func set_training_configuration(next_player_role: String) -> void:
	if next_player_role in ["Hider", "Seeker", "Random"]:
		player_role = next_player_role

func set_hiders(next_hiders: Array) -> void:
	hiders = next_hiders
	total_hiders = hiders.size()
	remaining_hiders = total_hiders
	for hider in hiders:
		if hider.has_signal("found") and not hider.found.is_connected(_on_hider_found):
				hider.found.connect(_on_hider_found)
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_refresh_roster_after_participants_changed()
	_emit_role_counts()

func set_seekers(next_seekers: Array) -> void:
	seekers = next_seekers
	_refresh_roster_after_participants_changed()
	_emit_role_counts()

func start_round() -> void:
	if not is_inside_tree() or network_authoritative:
		return
	_started = true
	round_number += 1
	timer.stop()
	_sync_roster()
	_reset_players()
	_refresh_hider_count()
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_emit_role_counts()
	_set_state(RoundState.WAITING, waiting_time, "Wachten op spelers")

func restart_round() -> void:
	if network_authoritative:
		return
	start_round()

func set_network_authoritative(value: bool) -> void:
	network_authoritative = value
	if network_authoritative:
		timer.stop()

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
	var roster := _roster()
	if roster:
		var participant_id: String = roster.get_id_for_node(target)
		if not participant_id.is_empty():
			roster.set_found(participant_id, true)
			if round_mode == "Infection":
				roster.set_role(participant_id, "SEEKER")
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
			if not _has_valid_participants():
				_set_state(RoundState.WAITING, 0, "Wachten op spelers\nMinimaal 1 Hider en 1 Seeker nodig")
				return
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
	var resolved_duration := duration
	if new_state == RoundState.WAITING and not _has_valid_participants():
		resolved_duration = 0
		message = "Wachten op spelers\nMinimaal 1 Hider en 1 Seeker nodig"
	seconds_left = resolved_duration
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
	if resolved_duration > 0:
		timer.start()

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
	var human_is_hider := _human_is_hider()
	if player.has_method("set_hider"):
		player.set_hider(human_is_hider)
	if player.has_method("set_shadow_policy"):
		player.set_shadow_policy(allow_shadow_toggle)
	if player.has_method("set_round_input_locked"):
		player.set_round_input_locked(true)
	var roster := _roster()
	if roster:
		var player_id: String = roster.get_id_for_node(player)
		if not player_id.is_empty():
			roster.set_role(player_id, "HIDER" if human_is_hider else "SEEKER")
			roster.set_found(player_id, false)
			roster.begin_round()
			_emit_role_counts()
	roles_assigned.emit()

func _reset_players() -> void:
	if player.has_method("reset_to_spawn"):
		var human_is_hider := _human_is_hider()
		var spawn := hider_spawn.global_transform if human_is_hider else seeker_spawn.global_transform
		player.reset_to_spawn(spawn, human_is_hider)
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
	var roster := _roster()
	if roster:
		var counts: Dictionary = roster.get_hider_counts()
		remaining_hiders = int(counts.get("remaining", 0))
		total_hiders = int(counts.get("total", 0))
		return
	remaining_hiders = 0
	for hider in hiders:
		if is_instance_valid(hider) and hider.has_method("is_hidden_alive") and hider.is_hidden_alive():
			remaining_hiders += 1

func _emit_role_counts() -> void:
	var roster := _roster()
	if roster:
		var counts: Dictionary = roster.get_role_counts()
		role_counts_changed.emit(int(counts.get("hiders", 0)), int(counts.get("seekers", 0)))
		return
	role_counts_changed.emit(remaining_hiders, seekers.size())

func _on_hider_found(_hider: Node) -> void:
	var roster := _roster()
	if roster:
		var participant_id: String = roster.get_id_for_node(_hider)
		if not participant_id.is_empty():
			roster.set_found(participant_id, true)
			if _hider.is_in_group("seekers"):
				roster.set_role(participant_id, "SEEKER")
	_refresh_hider_count()
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_emit_role_counts()
	if state == RoundState.SEARCHING and remaining_hiders <= 0:
		_finish_round("SEEKER")

func _sync_roster() -> void:
	var roster := _roster()
	if roster == null:
		return
	roster.clear()
	var human_role := "HIDER" if _human_is_hider() else "SEEKER"
	var display_name := "Player"
	var session := get_node_or_null("/root/SessionManager")
	if session and not session.display_name.is_empty():
		display_name = session.display_name
	roster.register_participant("player:local", player, display_name, human_role, false)
	for index in range(hiders.size()):
		var hider: Node = hiders[index]
		if is_instance_valid(hider):
			roster.register_participant("bot:hider:%d" % index, hider, hider.name, "HIDER", true)
	for index in range(seekers.size()):
		var seeker: Node = seekers[index]
		if is_instance_valid(seeker):
			roster.register_participant("bot:seeker:%d" % index, seeker, seeker.name, "SEEKER", true)
	roster.begin_round()
	roster_changed.emit()

func _refresh_roster_after_participants_changed() -> void:
	if _started and is_inside_tree():
		_sync_roster()
		_refresh_hider_count()
		hider_count_changed.emit(remaining_hiders, total_hiders)

func _on_roster_changed() -> void:
	if not _started or not is_inside_tree():
		return
	_refresh_hider_count()
	hider_count_changed.emit(remaining_hiders, total_hiders)
	_emit_role_counts()
	roster_changed.emit()

func _has_valid_participants() -> bool:
	var roster := _roster()
	if roster:
		var counts: Dictionary = roster.get_role_counts()
		return roster.get_participant_count() >= 2 and int(counts.get("hiders", 0)) >= 1 and int(counts.get("seekers", 0)) >= 1
	return player != null and (hiders.size() + seekers.size()) >= 1

func _human_is_hider() -> bool:
	if player_role == "Seeker":
		return false
	if player_role == "Hider":
		return true
	return not seekers.is_empty()

func _roster() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/MatchRoster")
