extends "res://scripts/services/supabase_rest_service.gd"

signal profile_loaded(profile: Dictionary)
signal profile_saved(profile: Dictionary)
signal profile_failed(message: String)

const DEFAULT_PROFILE := {
	"level": 1,
	"xp": 0,
	"selected_skin": "neutral",
	"body_materials": {},
	"favorite_pose": 0,
	"username": ""
}

var profile: Dictionary = DEFAULT_PROFILE.duplicate(true)

func load_profile() -> void:
	var user_id := _current_user_id()
	if user_id.is_empty():
		profile_failed.emit("Aanmelden is vereist om je profiel te laden.")
		return
	_request("/rest/v1/profiles?select=*&id=eq.%s&limit=1" % user_id.uri_encode(), HTTPClient.METHOD_GET, null, func(success: bool, data: Variant, message: String):
		if not success:
			profile_failed.emit(message)
			return
		var rows: Array = data if data is Array else []
		if rows.is_empty():
			profile = _profile_with_identity()
			profile_loaded.emit(profile.duplicate(true))
			return
		profile = _merge_profile(rows[0])
		profile_loaded.emit(profile.duplicate(true))
	)

func save_profile() -> void:
	var user_id := _current_user_id()
	if user_id.is_empty():
		profile_failed.emit("Aanmelden is vereist om je profiel op te slaan.")
		return
	profile = _profile_with_identity()
	var callback: Callable = func(success: bool, data: Variant, message: String):
		if not success:
			profile_failed.emit(message)
			return
		var rows: Array = data if data is Array else []
		if not rows.is_empty():
			profile = _merge_profile(rows[0])
		profile_saved.emit(profile.duplicate(true))
	_request("/rest/v1/profiles", HTTPClient.METHOD_POST, {
		"id": user_id,
		"username": profile["username"],
		"selected_skin": str(profile["selected_skin"]),
		"body_materials": profile["body_materials"],
		"favorite_pose": int(profile["favorite_pose"])
	}, callback, true, PackedStringArray(["Prefer: resolution=merge-duplicates,return=representation"]))

func set_level_xp(level: int, xp: int) -> void:
	profile["level"] = maxi(level, 1)
	profile["xp"] = maxi(xp, 0)

func set_selected_skin(skin_id: String) -> void:
	profile["selected_skin"] = skin_id.left(64)

func set_body_materials(materials: Dictionary) -> void:
	profile["body_materials"] = materials.duplicate(true)

func set_favorite_pose(pose_index: int) -> void:
	profile["favorite_pose"] = clampi(pose_index, 0, 8)

func get_profile() -> Dictionary:
	return profile.duplicate(true)

func _profile_with_identity() -> Dictionary:
	var result := profile.duplicate(true)
	var session := get_node_or_null("/root/SessionManager")
	if str(result.get("username", "")).is_empty() and session:
		result["username"] = session.display_name
	return result

func _merge_profile(value: Variant) -> Dictionary:
	var result := DEFAULT_PROFILE.duplicate(true)
	if value is Dictionary:
		for key in result.keys():
			if value.has(key):
				result[key] = value[key]
	return result
