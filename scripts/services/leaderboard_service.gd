extends "res://scripts/services/supabase_rest_service.gd"

signal leaderboard_loaded(entries: Array)
signal leaderboard_failed(message: String)

var entries: Array = []

func load_leaderboard(limit := 50) -> void:
	var safe_limit := clampi(limit, 1, 100)
	_request("/rest/v1/leaderboard_entries?select=user_id,username,level,xp,wins,updated_at&order=xp.desc,updated_at.asc&limit=%d" % safe_limit, HTTPClient.METHOD_GET, null, func(success: bool, data: Variant, message: String):
		if not success:
			leaderboard_failed.emit(message)
			return
		entries = data if data is Array else []
		leaderboard_loaded.emit(entries.duplicate(true))
	)

func get_entries() -> Array:
	return entries.duplicate(true)
