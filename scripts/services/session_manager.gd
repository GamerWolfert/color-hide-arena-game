extends Node

var access_token := ""
var refresh_token := ""
var user_id := ""
var email := ""
var display_name := ""

func is_logged_in() -> bool:
	return not access_token.is_empty() and not user_id.is_empty() and _is_access_token_current()

func set_session(data: Dictionary) -> bool:
	var user_data = data.get("user", {})
	if not user_data is Dictionary:
		return false
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	user_id = str(user_data.get("id", ""))
	email = str(user_data.get("email", ""))
	var metadata = user_data.get("user_metadata", {})
	if metadata is Dictionary:
		display_name = str(metadata.get("display_name", metadata.get("username", "")))
	if not is_logged_in():
		_clear_memory()
		return false
	save_session()
	return true

func save_session() -> void:
	var file := FileAccess.open("user://session.json", FileAccess.WRITE)

	if file == null:
		push_error("Kon sessie niet opslaan.")
		return

	file.store_string(JSON.stringify({
		"access_token": access_token,
		"refresh_token": refresh_token,
		"user_id": user_id,
		"email": email,
		"display_name": display_name
	}))

func load_session() -> void:
	_clear_memory()
	if not FileAccess.file_exists("user://session.json"):
		return

	var file := FileAccess.open("user://session.json", FileAccess.READ)

	if file == null:
		return

	var data = JSON.parse_string(file.get_as_text())

	if data is Dictionary:
		access_token = str(data.get("access_token", ""))
		refresh_token = str(data.get("refresh_token", ""))
		user_id = str(data.get("user_id", ""))
		email = str(data.get("email", ""))
		display_name = str(data.get("display_name", ""))
		if not is_logged_in():
			logout()

func logout() -> void:
	_clear_memory()
	if FileAccess.file_exists("user://session.json"):
		var path := ProjectSettings.globalize_path("user://session.json")
		DirAccess.remove_absolute(path)

func _clear_memory() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
	email = ""
	display_name = ""

func _is_access_token_current() -> bool:
	var parts := access_token.split(".")
	if parts.size() != 3:
		return false
	var payload := parts[1].replace("-", "+").replace("_", "/")
	while payload.length() % 4 != 0:
		payload += "="
	var decoded := Marshalls.base64_to_utf8(payload)
	if decoded.is_empty():
		return false
	var claims = JSON.parse_string(decoded)
	if not claims is Dictionary:
		return false
	var expires_at := float(claims.get("exp", 0.0))
	return expires_at > Time.get_unix_time_from_system() + 30.0
