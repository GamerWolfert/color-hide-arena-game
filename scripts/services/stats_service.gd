extends "res://scripts/services/supabase_rest_service.gd"

signal stats_loaded(stats: Dictionary)
signal stats_updated(stats: Dictionary)
signal stats_failed(message: String)

const LOCAL_STATS_PATH := "user://local_stats.json"
const DEFAULT_STATS := {
	"rounds": 0,
	"wins": 0,
	"losses": 0,
	"hider_rounds": 0,
	"seeker_rounds": 0,
	"successful_scans": 0,
	"times_found": 0,
	"xp_earned": 0
}

var stats: Dictionary = DEFAULT_STATS.duplicate(true)

func _ready() -> void:
	_load_local_stats()

func load_stats() -> void:
	var user_id := _current_user_id()
	if user_id.is_empty():
		stats_failed.emit("Aanmelden is vereist om statistieken te laden.")
		return
	_request("/rest/v1/player_stats?select=*&user_id=eq.%s&limit=1" % user_id.uri_encode(), HTTPClient.METHOD_GET, null, func(success: bool, data: Variant, message: String):
		if not success:
			stats_failed.emit(message)
			return
		var rows: Array = data if data is Array else []
		if not rows.is_empty():
			for key in stats.keys():
				if rows[0].has(key):
					stats[key] = int(rows[0][key])
		stats_loaded.emit(stats.duplicate(true))
	)

func record_local_event(event_name: String, amount := 1) -> void:
	if not stats.has(event_name):
		return
	stats[event_name] = maxi(int(stats[event_name]) + amount, 0)
	_save_local_stats()
	stats_updated.emit(stats.duplicate(true))

func record_training_round(won: bool, role: String, xp: int) -> void:
	record_local_event("rounds")
	record_local_event("wins" if won else "losses")
	record_local_event("hider_rounds" if role == "Hider" else "seeker_rounds")
	record_local_event("xp_earned", xp)

func submit_verified_match(match_payload: Dictionary) -> void:
	if not _is_authoritative_server():
		stats_failed.emit("Alleen een geautoriseerde matchserver mag multiplayerstatistieken indienen.")
		return
	var server_token := OS.get_environment("COLOR_HIDE_ARENA_SERVER_TOKEN")
	if server_token.is_empty():
		stats_failed.emit("Serverstatistieken wachten op COLOR_HIDE_ARENA_SERVER_TOKEN.")
		return
	var headers := PackedStringArray(["x-color-hide-server-token: " + server_token])
	var callback: Callable = func(success: bool, _data: Variant, message: String):
		if not success:
			stats_failed.emit(message)
	_request("/functions/v1/record-match-stats", HTTPClient.METHOD_POST, match_payload, callback, false, headers)

func get_stats() -> Dictionary:
	return stats.duplicate(true)

func _is_authoritative_server() -> bool:
	var network := get_node_or_null("/root/NetworkManager")
	return network != null and network.is_networked and network.is_server

func _load_local_stats() -> void:
	if not FileAccess.file_exists(LOCAL_STATS_PATH):
		return
	var file := FileAccess.open(LOCAL_STATS_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	if parsed is Dictionary:
		for key in stats.keys():
			if parsed.has(key):
				stats[key] = maxi(int(parsed[key]), 0)

func _save_local_stats() -> void:
	var file := FileAccess.open(LOCAL_STATS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(stats))
