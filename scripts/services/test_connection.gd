extends Node

var request: HTTPRequest

func _ready() -> void:
	request = HTTPRequest.new()
	add_child(request)

	request.timeout = 15.0
	request.request_completed.connect(_on_request_completed)

	var config := get_node_or_null("/root/SupabaseConfig")
	if config == null:
		print("SupabaseConfig is niet beschikbaar.")
		return
	var url: String = config.SUPABASE_URL + "/rest/v1/profiles?select=id&limit=1"

	var error := request.request(
		url,
		config.headers(),
		HTTPClient.METHOD_GET
	)

	if error != OK:
		print("Supabase-test kon niet starten. Foutcode: ", error)
	else:
		print("Supabase-test gestart...")

func _on_request_completed(
	result: int,
	response_code: int,
	response_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	print("Resultaatcode: ", result)
	print("HTTP-code: ", response_code)
	print("Antwoord: ", body.get_string_from_utf8())

	if response_code == 200:
		print("SUPABASE VERBINDING WERKT")
	elif response_code == 401:
		print("Verbinding werkt, maar aanmelden is verplicht.")
	elif response_code == 403:
		print("Verbinding werkt, maar RLS blokkeert deze aanvraag.")
	else:
		print("Supabase gaf een andere fout terug.")
