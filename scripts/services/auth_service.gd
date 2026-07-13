extends Node

signal signup_finished(success: bool, message: String)
signal login_finished(success: bool, message: String)

var signup_request: HTTPRequest
var login_request: HTTPRequest

func _ready() -> void:
	signup_request = HTTPRequest.new()
	login_request = HTTPRequest.new()

	add_child(signup_request)
	add_child(login_request)

	signup_request.timeout = 20.0
	login_request.timeout = 20.0

	signup_request.request_completed.connect(_on_signup_completed)
	login_request.request_completed.connect(_on_login_completed)

func sign_up(email: String, password: String, username: String) -> void:
	var config := _supabase_config()
	if config == null:
		signup_finished.emit(false, "SupabaseConfig is niet beschikbaar.")
		return
	var url: String = config.SUPABASE_URL + "/auth/v1/signup"

	var body := JSON.stringify({
		"email": email,
		"password": password,
		"data": {
			"username": username,
			"display_name": username
		}
	})

	var error := signup_request.request(
		url,
		config.headers(),
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		signup_finished.emit(false, "Registratie kon niet starten.")

func login(email: String, password: String) -> void:
	var config := _supabase_config()
	if config == null:
		login_finished.emit(false, "SupabaseConfig is niet beschikbaar.")
		return
	var url: String = config.SUPABASE_URL + "/auth/v1/token?grant_type=password"

	var body := JSON.stringify({
		"email": email,
		"password": password
	})

	var error := login_request.request(
		url,
		config.headers(),
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		login_finished.emit(false, "Inloggen kon niet starten.")

func _on_signup_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		signup_finished.emit(false, "network_error")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())

	if response_code >= 200 and response_code < 300:
		if not data is Dictionary:
			signup_finished.emit(false, "invalid_server_response")
			return
		if data.has("access_token"):
			var session := _session_manager()
			if session:
				session.set_session(data)
		if data.has("access_token"):
			signup_finished.emit(true, "Account gemaakt met actieve sessie.")
		else:
			signup_finished.emit(true, "email_confirmation_required")
	else:
		signup_finished.emit(false, _extract_error(data))

func _on_login_completed(
	result: int,
	response_code: int,
	_response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		login_finished.emit(false, "network_error")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())

	if response_code >= 200 and response_code < 300:
		if not data is Dictionary:
			login_finished.emit(false, "invalid_server_response")
			return
		var session := _session_manager()
		if session == null or not session.set_session(data):
			login_finished.emit(false, "invalid_session")
			return
		login_finished.emit(true, "Inloggen gelukt.")
	else:
		login_finished.emit(false, _extract_error(data))

func _extract_error(data) -> String:
	if data is Dictionary:
		if data.has("msg"):
			return str(data["msg"])

		if data.has("error_description"):
			return str(data["error_description"])

		if data.has("message"):
			return str(data["message"])

	return "Er is een onbekende fout opgetreden."

func _supabase_config() -> Node:
	return get_node_or_null("/root/SupabaseConfig")

func _session_manager() -> Node:
	return get_node_or_null("/root/SessionManager")
