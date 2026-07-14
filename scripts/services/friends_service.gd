extends "res://scripts/services/supabase_rest_service.gd"

signal friends_loaded(friends: Array)
signal recent_players_loaded(players: Array)
signal friends_changed
signal friends_failed(message: String)

var friends: Array = []
var recent_players: Array = []

func load_friends() -> void:
	_request("/rest/v1/friends?select=friend_user_id,status,created_at&order=created_at.desc", HTTPClient.METHOD_GET, null, func(success: bool, data: Variant, message: String):
		if not success:
			friends_failed.emit(message)
			return
		friends = data if data is Array else []
		friends_loaded.emit(friends.duplicate(true))
	)

func add_friend(friend_user_id: String) -> void:
	if not _is_uuid(friend_user_id) or friend_user_id == _current_user_id():
		friends_failed.emit("Ongeldige vriend-ID.")
		return
	var callback: Callable = func(success: bool, _data: Variant, message: String):
		if not success:
			friends_failed.emit(message)
			return
		friends_changed.emit()
		load_friends()
	_request("/rest/v1/friends", HTTPClient.METHOD_POST, {"user_id": _current_user_id(), "friend_user_id": friend_user_id, "status": "pending"}, callback, true, PackedStringArray(["Prefer: resolution=merge-duplicates,return=minimal"]))

func remove_friend(friend_user_id: String) -> void:
	_request("/rest/v1/friends?friend_user_id=eq.%s" % friend_user_id.uri_encode(), HTTPClient.METHOD_DELETE, null, func(success: bool, _data: Variant, message: String):
		if not success:
			friends_failed.emit(message)
			return
		friends_changed.emit()
		load_friends()
	)

func set_friend_status(friend_user_id: String, status: String) -> void:
	if status not in ["pending", "accepted", "blocked"]:
		return
	_request("/rest/v1/friends?friend_user_id=eq.%s" % friend_user_id.uri_encode(), HTTPClient.METHOD_PATCH, {"status": status}, func(success: bool, _data: Variant, message: String):
		if not success:
			friends_failed.emit(message)
			return
		friends_changed.emit()
		load_friends()
	)

func record_recent_player(player_user_id: String) -> void:
	if not _is_uuid(player_user_id) or player_user_id == _current_user_id():
		return
	var callback: Callable = func(_success: bool, _data: Variant, _message: String):
		pass
	_request("/rest/v1/recent_players", HTTPClient.METHOD_POST, {"owner_id": _current_user_id(), "player_id": player_user_id, "last_seen": Time.get_datetime_string_from_system(true), "encounter_count": 1}, callback, true, PackedStringArray(["Prefer: resolution=merge-duplicates,return=minimal"]))

func load_recent_players() -> void:
	_request("/rest/v1/recent_players?select=player_id,last_seen,encounter_count&order=last_seen.desc&limit=25", HTTPClient.METHOD_GET, null, func(success: bool, data: Variant, message: String):
		if not success:
			friends_failed.emit(message)
			return
		recent_players = data if data is Array else []
		recent_players_loaded.emit(recent_players.duplicate(true))
	)

func _is_uuid(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$")
	return regex.search(value) != null
