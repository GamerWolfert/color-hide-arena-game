extends Node

const REQUEST_TIMEOUT := 20.0

func _request(path: String, method: int, body: Variant, callback: Callable, require_auth := true, extra_headers := PackedStringArray()) -> void:
	var config := get_node_or_null("/root/SupabaseConfig")
	if config == null:
		callback.call(false, {}, "SupabaseConfig is niet beschikbaar.")
		return
	var session := get_node_or_null("/root/SessionManager")
	var access_token := ""
	if require_auth:
		if session == null or not session.is_logged_in():
			callback.call(false, {}, "Aanmelden is vereist.")
			return
		access_token = session.access_token
	var headers: PackedStringArray = config.headers(access_token)
	headers.append("Prefer: return=representation")
	for header in extra_headers:
		headers.append(header)
	var request := HTTPRequest.new()
	request.timeout = REQUEST_TIMEOUT
	add_child(request)
	request.request_completed.connect(func(result: int, response_code: int, _response_headers: PackedStringArray, data: PackedByteArray):
		request.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS:
			callback.call(false, {}, "Netwerkverbinding met Supabase mislukt.")
			return
		var parsed: Variant = {}
		var text := data.get_string_from_utf8()
		if not text.is_empty():
			parsed = JSON.parse_string(text)
		if response_code < 200 or response_code >= 300:
			callback.call(false, parsed, _error_message(parsed, response_code))
			return
		callback.call(true, parsed, "")
	)
	var url: String = config.SUPABASE_URL + path
	var request_body := ""
	if body != null:
		request_body = JSON.stringify(body)
	var error := request.request(url, headers, method, request_body)
	if error != OK:
		request.queue_free()
		callback.call(false, {}, "Supabase-aanvraag kon niet starten.")

func _current_user_id() -> String:
	var session := get_node_or_null("/root/SessionManager")
	return str(session.user_id) if session and session.is_logged_in() else ""

func _error_message(data: Variant, response_code: int) -> String:
	if data is Dictionary:
		for key in ["message", "msg", "error_description", "hint"]:
			if data.has(key):
				return str(data[key])
	return "Supabase-aanvraag mislukt (%d)." % response_code
