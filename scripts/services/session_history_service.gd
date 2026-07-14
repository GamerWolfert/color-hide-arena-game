extends Node

const SAVE_PATH := "user://session_history.json"

var current_account_key := "guest"
var _history: Dictionary = {}

func _ready() -> void:
	_load_history()
	refresh_account()

func refresh_account() -> void:
	current_account_key = _get_account_key()

func get_last_session() -> Dictionary:
	refresh_account()
	var data = _history.get(current_account_key, {})
	return data.duplicate() if data is Dictionary else {}

func record_round(mode: String, role: String, result: String, xp: int) -> void:
	refresh_account()
	if current_account_key == "guest":
		return
	_history[current_account_key] = {
		"mode": mode,
		"role": role,
		"result": result,
		"xp": maxi(xp, 0),
		"timestamp": Time.get_unix_time_from_system()
	}
	_save_history()

func _get_account_key() -> String:
	var session := get_node_or_null("/root/SessionManager")
	if session and not session.display_name.is_empty():
		return str(session.display_name).strip_edges().to_lower()
	if session and not session.email.is_empty():
		return str(session.email).strip_edges().to_lower()
	return "guest"

func _load_history() -> void:
	_history = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_history = parsed

func _save_history() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_history))
