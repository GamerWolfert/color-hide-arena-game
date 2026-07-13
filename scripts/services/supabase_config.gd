extends Node

const SUPABASE_URL := "https://dfsacolwfzglbcwbibmy.supabase.co"
const SUPABASE_KEY := "sb_publishable_2k4l9RdqX0B1fThgMR3_CA_WzNDXVgv"

static func headers(access_token: String = "") -> PackedStringArray:
	var result := PackedStringArray([
		"apikey: " + SUPABASE_KEY,
		"Content-Type: application/json"
	])

	if not access_token.is_empty():
		result.append("Authorization: Bearer " + access_token)

	return result
