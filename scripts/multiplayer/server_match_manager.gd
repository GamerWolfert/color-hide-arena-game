extends Node

signal phase_changed(phase_name: String, seconds_left: int)
signal timer_changed(seconds_left: int)
signal round_message(message: String)
signal round_finished(winner: String)
signal hider_count_changed(remaining: int, total: int)
signal role_counts_changed(hiders: int, seekers: int)
signal state_changed(state_name: String)
signal score_changed(peer_id: int, score: int)

const AVATAR_SCENE := preload("res://scenes/multiplayer/network_avatar.tscn")
const PHASES := ["WAITING", "ROLE_ASSIGNMENT", "HIDING", "SEARCHING", "RESULTS", "RESTARTING"]
const PHASE_DURATIONS := {
	"WAITING": 3,
	"ROLE_ASSIGNMENT": 2,
	"HIDING": 18,
	"SEARCHING": 45,
	"RESULTS": 6,
	"RESTARTING": 2
}
const VALID_PARTS := ["Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"]
const MAP_MIN := Vector2(-24.0, -18.0)
const MAP_MAX := Vector2(24.0, 18.0)

var network: Node
var authoritative := false
var phase := "WAITING"
var seconds_left := 0
var round_number := 0
var players: Dictionary = {}
var gameplay_root: Node
var local_player: Node
var _avatars: Dictionary = {}
var _phase_accumulator := 0.0
var _snapshot_accumulator := 0.0

func setup(manager: Node) -> void:
	network = manager
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_authoritative_match() -> void:
	authoritative = true
	register_peer(1)
	_start_round()

func stop_match() -> void:
	authoritative = false
	players.clear()
	for avatar in _avatars.values():
		if is_instance_valid(avatar):
			avatar.queue_free()
	_avatars.clear()

func bind_gameplay_world(root: Node, player: Node) -> void:
	gameplay_root = root
	local_player = player
	if authoritative:
		register_peer(1)
		server_update_local_state(1, _state_from_player(player))

func register_peer(peer_id: int) -> void:
	if players.has(peer_id):
		return
	print("MATCH_PLAYER_REGISTERED peer=%d" % peer_id)
	players[peer_id] = {
		"id": peer_id,
		"position": _spawn_position(peer_id, "HIDER"),
		"yaw": 0.0,
		"pitch": 0.0,
		"velocity": Vector3.ZERO,
		"move": Vector2.ZERO,
		"role": "HIDER",
		"found": false,
		"score": 0,
		"pose": 0,
		"colors": {},
		"energy": 100.0,
		"scan_cooldown": 0.0
	}
	if authoritative:
		_assign_roles()
		if phase == "WAITING" and _has_minimum_players():
			_set_phase("WAITING", "Wachten op spelers")
		else:
			_emit_counts()

func remove_peer(peer_id: int) -> void:
	players.erase(peer_id)
	if _avatars.has(peer_id):
		if is_instance_valid(_avatars[peer_id]):
			_avatars[peer_id].queue_free()
		_avatars.erase(peer_id)
	_emit_counts()
	if authoritative and not _has_minimum_players():
		_set_phase("WAITING", "Wachten op spelers")

func send_hello() -> void:
	if network and not network.is_server:
		var session := get_node_or_null("/root/SessionManager")
		var display_name := "Player"
		var user_id := ""
		if session and not session.display_name.is_empty():
			display_name = session.display_name
		if session:
			user_id = session.user_id
		client_hello.rpc_id(1, display_name, user_id)

@rpc("any_peer", "call_remote", "reliable")
func client_hello(display_name: String, user_id: String) -> void:
	if not authoritative:
		return
	var sender := multiplayer.get_remote_sender_id()
	register_peer(sender)
	var state: Dictionary = players.get(sender, {})
	state["display_name"] = display_name.left(24)
	state["user_id"] = user_id if _is_uuid(user_id) else ""
	players[sender] = state
	_send_snapshot_to(sender)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func submit_input(payload: Dictionary) -> void:
	if not authoritative:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender <= 0 or not players.has(sender):
		return
	_server_apply_input(sender, payload)

func server_update_local_state(peer_id: int, payload: Dictionary) -> void:
	if not authoritative or not players.has(peer_id):
		return
	var state: Dictionary = players[peer_id]
	state["position"] = payload.get("position", state["position"])
	state["yaw"] = float(payload.get("yaw", state["yaw"]))
	state["pitch"] = float(payload.get("pitch", state["pitch"]))
	state["pose"] = _valid_pose(payload.get("pose", state["pose"]))
	state["colors"] = _sanitize_colors(payload.get("colors", state["colors"]))
	state["sprint"] = bool(payload.get("sprint", false))
	state["crouch"] = bool(payload.get("crouch", false))
	players[peer_id] = state

func server_request_scan(peer_id: int, direction: Vector3) -> void:
	if not authoritative:
		return
	_process_scan(peer_id, direction)

@rpc("any_peer", "call_remote", "reliable")
func request_scan(direction: Vector3) -> void:
	if not authoritative:
		return
	_process_scan(multiplayer.get_remote_sender_id(), direction)

func server_request_appearance(peer_id: int, part_name: String, color: Color, pose_index: int) -> void:
	_apply_appearance(peer_id, part_name, color.to_html(true), pose_index)

@rpc("any_peer", "call_remote", "reliable")
func request_appearance(part_name: String, color_hex: String, pose_index: int) -> void:
	if not authoritative:
		return
	_apply_appearance(multiplayer.get_remote_sender_id(), part_name, color_hex, pose_index)

func _process(delta: float) -> void:
	if not authoritative:
		return
	_phase_accumulator += delta
	_snapshot_accumulator += delta
	for peer_id in players.keys():
		var id := int(peer_id)
		if id != 1:
			_server_move(id, delta)
		var state: Dictionary = players[id]
		state["scan_cooldown"] = maxf(float(state.get("scan_cooldown", 0.0)) - delta, 0.0)
		players[id] = state
	if _phase_accumulator >= 1.0:
		_phase_accumulator -= 1.0
		seconds_left = maxi(seconds_left - 1, 0)
		timer_changed.emit(seconds_left)
		if seconds_left == 0:
			if phase != "WAITING" or _has_minimum_players():
				_advance_phase()
	if _snapshot_accumulator >= 0.05:
		_snapshot_accumulator = 0.0
		_broadcast_snapshot()

func _start_round() -> void:
	round_number += 1
	for peer_id in players.keys():
		var state: Dictionary = players[peer_id]
		state["found"] = false
		state["score"] = 0
		state["energy"] = 100.0
		state["scan_cooldown"] = 0.0
		state["position"] = _spawn_position(int(peer_id), "HIDER")
		players[peer_id] = state
	_set_phase("WAITING", "Wachten op spelers")

func _advance_phase() -> void:
	match phase:
		"WAITING":
			if not _has_minimum_players():
				_set_phase("WAITING", "Wachten op spelers")
				return
			_set_phase("ROLE_ASSIGNMENT", "Rollen worden verdeeld")
		"ROLE_ASSIGNMENT":
			_assign_roles()
			_set_phase("HIDING", "Verstopfase - kies kleur en pose")
		"HIDING":
			_set_phase("SEARCHING", "Zoekfase - server controleert treffers")
		"SEARCHING":
			_finish_round("HIDER")
		"RESULTS":
			_set_phase("RESTARTING", "Nieuwe ronde wordt voorbereid")
		"RESTARTING":
			_start_round()

func _assign_roles() -> void:
	var ids := players.keys()
	ids.sort()
	for index in range(ids.size()):
		var peer_id := int(ids[index])
		var state: Dictionary = players[peer_id]
		state["role"] = "SEEKER" if ids.size() > 1 and index == ids.size() - 1 else "HIDER"
		state["found"] = false
		state["position"] = _spawn_position(peer_id, state["role"])
		players[peer_id] = state
	_emit_counts()

func _set_phase(next_phase: String, message: String) -> void:
	phase = next_phase
	seconds_left = int(PHASE_DURATIONS.get(phase, 0))
	if phase == "WAITING" and not _has_minimum_players():
		seconds_left = 0
		message = "Wachten op spelers\nMinimaal 1 Hider en 1 Seeker nodig"
	print("MATCH_PHASE phase=%s seconds=%d" % [phase, seconds_left])
	phase_changed.emit(phase, seconds_left)
	timer_changed.emit(seconds_left)
	state_changed.emit(phase)
	round_message.emit(message)
	_broadcast_snapshot()

func _has_minimum_players() -> bool:
	return players.size() >= 2

func _finish_round(winner: String) -> void:
	_set_phase("RESULTS", "%s wint de ronde" % winner)
	round_finished.emit(winner)
	for peer_id in players.keys():
		var state: Dictionary = players[peer_id]
		if state["role"] == winner:
			state["score"] = int(state["score"]) + 275
		players[peer_id] = state
		score_changed.emit(int(peer_id), int(state["score"]))
	var stats_service := get_node_or_null("/root/StatsService")
	if stats_service and stats_service.has_method("submit_verified_match"):
		stats_service.submit_verified_match(_verified_stats_payload(winner))

func _verified_stats_payload(winner: String) -> Dictionary:
	var verified_players: Array = []
	for state in players.values():
		var user_id := str(state.get("user_id", ""))
		if not _is_uuid(user_id):
			continue
		var role := str(state.get("role", "HIDER"))
		verified_players.append({
			"user_id": user_id,
			"role": role,
			"won": role == winner,
			"xp": 275 if role == winner else 90
		})
	return {"round_id": round_number, "mode": "Infection", "winner": winner, "players": verified_players}

func _server_apply_input(peer_id: int, payload: Dictionary) -> void:
	var state: Dictionary = players[peer_id]
	state["move"] = payload.get("move", Vector2.ZERO)
	state["yaw"] = float(payload.get("yaw", state["yaw"]))
	state["pitch"] = float(payload.get("pitch", state["pitch"]))
	state["pose"] = _valid_pose(payload.get("pose", state["pose"]))
	state["colors"] = _sanitize_colors(payload.get("colors", state["colors"]))
	players[peer_id] = state

func _server_move(peer_id: int, delta: float) -> void:
	var state: Dictionary = players[peer_id]
	var move: Vector2 = state.get("move", Vector2.ZERO)
	if move.length() > 1.0:
		move = move.normalized()
	var yaw := float(state.get("yaw", 0.0))
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var direction := (right * move.x + forward * -move.y)
	if direction.length() > 1.0:
		direction = direction.normalized()
	var speed := 8.5 if bool(state.get("sprint", false)) else 5.5
	if bool(state.get("crouch", false)):
		speed = 3.0
	var position: Vector3 = state.get("position", Vector3.ZERO)
	position += direction * speed * delta
	position.x = clampf(position.x, MAP_MIN.x, MAP_MAX.x)
	position.z = clampf(position.z, MAP_MIN.y, MAP_MAX.y)
	state["position"] = position
	players[peer_id] = state

func _process_scan(peer_id: int, direction: Vector3) -> void:
	if not players.has(peer_id) or phase != "SEARCHING":
		return
	var seeker: Dictionary = players[peer_id]
	if seeker.get("role", "HIDER") != "SEEKER" or float(seeker.get("scan_cooldown", 0.0)) > 0.0:
		return
	seeker["scan_cooldown"] = 0.9
	seeker["energy"] = maxf(float(seeker.get("energy", 100.0)) - 8.0, 0.0)
	var origin: Vector3 = seeker.get("position", Vector3.ZERO) + Vector3.UP
	var look := direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	var target_id := -1
	var best_distance := 99.0
	for candidate_id in players.keys():
		var candidate: Dictionary = players[candidate_id]
		if candidate.get("role", "HIDER") != "HIDER" or bool(candidate.get("found", false)):
			continue
		var target_position: Vector3 = candidate.get("position", Vector3.ZERO) + Vector3.UP
		var offset := target_position - origin
		var distance := offset.length()
		if distance <= 10.0 and distance < best_distance and look.dot(offset.normalized()) >= 0.45:
			target_id = int(candidate_id)
			best_distance = distance
	if target_id >= 0:
		var target: Dictionary = players[target_id]
		target["found"] = true
		target["role"] = "SEEKER"
		target["score"] = int(target["score"]) + 90
		players[target_id] = target
		seeker["score"] = int(seeker["score"]) + 275
		players[peer_id] = seeker
		round_message.emit("Server bevestigt treffer")
		_emit_counts()
		if _remaining_hiders() <= 0:
			_finish_round("SEEKER")

func _apply_appearance(peer_id: int, part_name: String, color_hex: String, next_pose: int) -> void:
	if not authoritative or not players.has(peer_id) or phase != "HIDING" or not VALID_PARTS.has(part_name):
		return
	var color := Color.from_string(color_hex, Color.WHITE)
	if color == Color.WHITE and color_hex.to_lower() != "ffffffff":
		return
	var state: Dictionary = players[peer_id]
	if state.get("role", "HIDER") != "HIDER":
		return
	var colors: Dictionary = state.get("colors", {})
	colors[part_name] = color.to_html(true)
	state["colors"] = colors
	state["pose"] = _valid_pose(next_pose)
	players[peer_id] = state

func _broadcast_snapshot() -> void:
	if not network or not network.is_networked:
		return
	var snapshot := _snapshot_data()
	if authoritative:
		client_receive_snapshot.rpc(snapshot, phase, seconds_left)

func _send_snapshot_to(peer_id: int) -> void:
	if not authoritative:
		return
	client_receive_snapshot.rpc_id(peer_id, _snapshot_data(), phase, seconds_left)

@rpc("authority", "call_remote", "unreliable_ordered", 1)
func client_receive_snapshot(snapshot: Array, next_phase: String, next_seconds: int) -> void:
	if authoritative:
		return
	phase = next_phase
	seconds_left = next_seconds
	_apply_client_snapshot(snapshot)
	phase_changed.emit(phase, seconds_left)
	timer_changed.emit(seconds_left)
	state_changed.emit(phase)

func _apply_client_snapshot(snapshot: Array) -> void:
	var seen: Dictionary = {}
	for raw_state in snapshot:
		var state: Dictionary = raw_state
		var peer_id := int(state.get("id", -1))
		if peer_id < 0:
			continue
		seen[peer_id] = true
		if network and peer_id == network.local_peer_id:
			_apply_local_state(state)
		else:
			_apply_remote_state(peer_id, state)
	for peer_id in _avatars.keys():
		if not seen.has(peer_id):
			if is_instance_valid(_avatars[peer_id]):
				_avatars[peer_id].queue_free()
			_avatars.erase(peer_id)
	_emit_counts_from_snapshot(snapshot)

func _apply_local_state(state: Dictionary) -> void:
	if not local_player or not is_instance_valid(local_player):
		return
	var server_position: Vector3 = state.get("position", local_player.global_position)
	if local_player.global_position.distance_to(server_position) > 0.7:
		local_player.global_position = local_player.global_position.lerp(server_position, 0.65)
	if local_player.has_method("set_hider"):
		local_player.set_hider(state.get("role", "HIDER") == "HIDER")
	if local_player.get("pose_index") != null and int(local_player.pose_index) != int(state.get("pose", 0)):
		if local_player.has_method("_set_pose"):
			local_player._set_pose(int(state.get("pose", 0)))
	_apply_colors_to_player(local_player, state.get("colors", {}))

func _apply_remote_state(peer_id: int, state: Dictionary) -> void:
	if not gameplay_root:
		return
	if not _avatars.has(peer_id) or not is_instance_valid(_avatars[peer_id]):
		var avatar := AVATAR_SCENE.instantiate()
		avatar.name = "NetworkAvatar%d" % peer_id
		gameplay_root.add_child(avatar)
		_avatars[peer_id] = avatar
	_avatars[peer_id].apply_network_state(state)

func _apply_colors_to_player(player: Node, colors: Dictionary) -> void:
	if not player.has_method("set_body_part_style"):
		return
	for part_name in colors.keys():
		var color := Color.from_string(str(colors[part_name]), Color.WHITE)
		player.set_body_part_style(str(part_name), color)

func _snapshot_data() -> Array:
	var result: Array = []
	for peer_id in players.keys():
		var state: Dictionary = players[peer_id].duplicate(true)
		state.erase("move")
		state.erase("scan_cooldown")
		result.append(state)
	return result

func _emit_counts() -> void:
	var hiders := _remaining_hiders()
	var total := players.size()
	hider_count_changed.emit(hiders, total)
	var seekers := total - hiders
	role_counts_changed.emit(hiders, seekers)

func _emit_counts_from_snapshot(snapshot: Array) -> void:
	var hiders := 0
	var seekers := 0
	for state in snapshot:
		if state.get("role", "HIDER") == "HIDER" and not bool(state.get("found", false)):
			hiders += 1
		else:
			seekers += 1
	hider_count_changed.emit(hiders, hiders + seekers)
	role_counts_changed.emit(hiders, seekers)

func _remaining_hiders() -> int:
	var total := 0
	for state in players.values():
		if state.get("role", "HIDER") == "HIDER" and not bool(state.get("found", false)):
			total += 1
	return total

func _spawn_position(peer_id: int, role: String) -> Vector3:
	if gameplay_root:
		var markers := get_tree().get_nodes_in_group("training_spawns")
		if not markers.is_empty():
			var marker: Node3D = markers[abs(peer_id) % markers.size()]
			return marker.global_position
	return Vector3(-5.0 + (peer_id % 5) * 2.5, 1.2, 10.0 if role == "HIDER" else -10.0)

func _state_from_player(player: Node) -> Dictionary:
	var state := {
		"position": player.global_position,
		"yaw": player.get_node("YawRoot").rotation.y,
		"pitch": player.get_node("YawRoot/PitchRoot").rotation.x,
		"pose": int(player.get("pose_index")) if player.get("pose_index") != null else 0,
		"colors": {}
	}
	return state

func _sanitize_colors(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for part_name in value.keys():
			if VALID_PARTS.has(str(part_name)):
				var color := Color.from_string(str(value[part_name]), Color.WHITE)
				result[str(part_name)] = color.to_html(true)
	return result

func _valid_pose(value: Variant) -> int:
	return clampi(int(value), 0, 8)

func _is_uuid(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")
	return regex.search(value) != null
