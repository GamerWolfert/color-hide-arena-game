extends Node

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

var resolution := Vector2i(1280, 720)
var fullscreen := false
var graphics_quality := "Middel"
var mouse_sensitivity := 0.0025
var master_volume := 0.85
var music_volume := 0.70
var effects_volume := 0.80

func _ready() -> void:
	load_settings()
	apply_settings()

func apply_settings() -> void:
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("Effects", effects_volume)
	ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", _msaa_for_quality())
	settings_changed.emit()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("video", "resolution", resolution)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "graphics_quality", graphics_quality)
	config.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "effects_volume", effects_volume)
	config.save(SAVE_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	resolution = config.get_value("video", "resolution", resolution)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	graphics_quality = config.get_value("video", "graphics_quality", graphics_quality)
	mouse_sensitivity = config.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	master_volume = config.get_value("audio", "master_volume", master_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	effects_volume = config.get_value("audio", "effects_volume", effects_volume)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var clamped: float = clamp(linear_value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(max(clamped, 0.001)))
	AudioServer.set_bus_mute(bus_index, clamped <= 0.0)

func _msaa_for_quality() -> int:
	match graphics_quality:
		"Laag":
			return 0
		"Hoog":
			return 3
		_:
			return 1
