extends Node

signal roster_changed
signal participant_added(participant_id: String)
signal participant_removed(participant_id: String)
signal role_changed(participant_id: String, role: String)
signal hider_found(participant_id: String)

const HIDER := "HIDER"
const SEEKER := "SEEKER"
const SPECTATOR := "SPECTATOR"

var participants: Dictionary = {}

func clear() -> void:
	participants.clear()
	roster_changed.emit()

func register_participant(participant_id: String, node: Node, display_name: String, role: String, is_bot: bool) -> void:
	if participant_id.is_empty() or node == null:
		return
	var safe_role := _safe_role(role)
	var existed := participants.has(participant_id)
	var participant: Dictionary = participants.get(participant_id, {})
	participant["player_id"] = participant_id
	participant["node"] = node
	participant["display_name"] = display_name.left(32)
	participant["role"] = safe_role
	participant["initial_role"] = str(participant.get("initial_role", safe_role))
	participant["is_bot"] = is_bot
	participant["connected"] = true
	participant["active"] = true
	participant["found"] = bool(participant.get("found", false))
	participants[participant_id] = participant
	if not existed:
		participant_added.emit(participant_id)
		if node.has_signal("tree_exiting"):
			node.tree_exiting.connect(func(): unregister_participant(participant_id), CONNECT_ONE_SHOT)
	roster_changed.emit()

func begin_round() -> void:
	for participant_id in participants.keys():
		var participant: Dictionary = participants[participant_id]
		participant["initial_role"] = participant.get("role", SPECTATOR)
		participant["found"] = false
		participant["connected"] = true
		participant["active"] = true
		participants[participant_id] = participant
	roster_changed.emit()

func unregister_participant(participant_id: String) -> void:
	if not participants.has(participant_id):
		return
	participants.erase(participant_id)
	participant_removed.emit(participant_id)
	roster_changed.emit()

func set_role(participant_id: String, role: String) -> void:
	if not participants.has(participant_id):
		return
	var participant: Dictionary = participants[participant_id]
	var safe_role := _safe_role(role)
	if participant.get("role", SPECTATOR) == safe_role:
		return
	participant["role"] = safe_role
	participants[participant_id] = participant
	role_changed.emit(participant_id, safe_role)
	roster_changed.emit()

func set_found(participant_id: String, found: bool) -> void:
	if not participants.has(participant_id):
		return
	var participant: Dictionary = participants[participant_id]
	participant["found"] = found
	participants[participant_id] = participant
	if found:
		hider_found.emit(participant_id)
	roster_changed.emit()

func set_active(participant_id: String, active: bool) -> void:
	if not participants.has(participant_id):
		return
	var participant: Dictionary = participants[participant_id]
	participant["active"] = active
	participants[participant_id] = participant
	roster_changed.emit()

func get_role_counts() -> Dictionary:
	var hiders := 0
	var seekers := 0
	for participant in participants.values():
		if not _is_active(participant):
			continue
		match participant.get("role", SPECTATOR):
			HIDER:
				if not bool(participant.get("found", false)):
					hiders += 1
			SEEKER:
				seekers += 1
	return {"hiders": hiders, "seekers": seekers}

func get_hider_counts() -> Dictionary:
	var remaining := 0
	var total := 0
	for participant in participants.values():
		if not _is_active(participant):
			continue
		if participant.get("initial_role", SPECTATOR) == HIDER:
			total += 1
		if participant.get("role", SPECTATOR) == HIDER and not bool(participant.get("found", false)):
			remaining += 1
	return {"remaining": remaining, "total": total}

func get_participant_count() -> int:
	var count := 0
	for participant in participants.values():
		if _is_active(participant) and participant.get("role", SPECTATOR) != SPECTATOR:
			count += 1
	return count

func get_snapshot() -> Array:
	var result: Array = []
	for participant in participants.values():
		var snapshot: Dictionary = participant.duplicate()
		snapshot.erase("node")
		result.append(snapshot)
	return result

func get_id_for_node(node: Node) -> String:
	for participant_id in participants.keys():
		if participants[participant_id].get("node") == node:
			return str(participant_id)
	return ""

func _is_active(participant: Dictionary) -> bool:
	return bool(participant.get("connected", false)) and bool(participant.get("active", false))

func _safe_role(role: String) -> String:
	var normalized := role.to_upper()
	return normalized if normalized in [HIDER, SEEKER, SPECTATOR] else SPECTATOR
