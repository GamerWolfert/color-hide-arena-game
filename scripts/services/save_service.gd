extends "res://scripts/services/supabase_rest_service.gd"

signal save_loaded(save_data: Dictionary)
signal save_completed
signal save_failed(message: String)

var last_save: Dictionary = {}

func save_all() -> void:
	var user_id := _current_user_id()
	if user_id.is_empty():
		save_failed.emit("Aanmelden is vereist om cloudsave te gebruiken.")
		return
	var profile_service := get_node_or_null("/root/ProfileService")
	if profile_service:
		profile_service.save_profile()
	var payload := {
		"settings": _settings_snapshot(),
		"selected_skin": str(profile_service.profile.get("selected_skin", "neutral")) if profile_service else "neutral",
		"body_materials": profile_service.profile.get("body_materials", {}) if profile_service else {},
		"favorite_pose": int(profile_service.profile.get("favorite_pose", 0)) if profile_service else 0
	}
	last_save = payload.duplicate(true)
	var callback: Callable = func(success: bool, _data: Variant, message: String):
		if not success:
			save_failed.emit(message)
			return
		save_completed.emit()
	_request("/rest/v1/player_saves", HTTPClient.METHOD_POST, {"user_id": user_id, "payload": payload}, callback, true, PackedStringArray(["Prefer: resolution=merge-duplicates,return=minimal"]))

func load_cloud_save() -> void:
	var user_id := _current_user_id()
	if user_id.is_empty():
		save_failed.emit("Aanmelden is vereist om cloudsave te laden.")
		return
	_request("/rest/v1/player_saves?select=payload&user_id=eq.%s&limit=1" % user_id.uri_encode(), HTTPClient.METHOD_GET, null, func(success: bool, data: Variant, message: String):
		if not success:
			save_failed.emit(message)
			return
		var rows: Array = data if data is Array else []
		last_save = rows[0].get("payload", {}) if not rows.is_empty() and rows[0] is Dictionary else {}
		_apply_settings(last_save.get("settings", {}))
		save_loaded.emit(last_save.duplicate(true))
	)

func save_settings_snapshot() -> void:
	save_all()

func _settings_snapshot() -> Dictionary:
	var settings := get_node_or_null("/root/SettingsService")
	if settings and settings.has_method("to_dictionary"):
		return settings.to_dictionary()
	return {}

func _apply_settings(value: Variant) -> void:
	var settings := get_node_or_null("/root/SettingsService")
	if settings and value is Dictionary and settings.has_method("apply_dictionary"):
		settings.apply_dictionary(value)
