extends Node

signal settings_changed

const SAVE_PATH := "user://settings.cfg"
const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const DEFAULT_GRAPHICS := "Middel"

var resolution := DEFAULT_RESOLUTION
var window_mode := "windowed"
var fullscreen := false
var borderless := false
var vsync_enabled := true
var graphics_quality := DEFAULT_GRAPHICS
var render_scale := 1.0
var shadows_enabled := true
var anti_aliasing := "2x"

var mouse_sensitivity := 0.0025
var controller_sensitivity := 2.8
var mobile_camera_sensitivity := 1.0
var invert_y := false

var master_volume := 0.85
var music_volume := 0.70
var effects_volume := 0.80
var voice_chat_enabled := false

var joystick_size := 1.0
var touch_button_opacity := 0.78
var touch_controls_position := "Standaard"
var vibration_enabled := true
var aim_assist_enabled := false
var force_mobile_ui_on_desktop := false
var debug_name_labels := false
var debug_xray_enabled := false

func _ready() -> void:
    load_settings()
    apply_settings()

func apply_settings() -> void:
    fullscreen = window_mode == "fullscreen"
    match window_mode:
        "fullscreen":
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        "borderless":
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
        _:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
            DisplayServer.window_set_size(resolution)
    borderless = window_mode == "borderless"
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)
    _set_bus_volume("Master", master_volume)
    _set_bus_volume("Music", music_volume)
    _set_bus_volume("Effects", effects_volume)
    ProjectSettings.set_setting("rendering/anti_aliasing/quality/msaa_3d", _msaa_for_quality())
    ProjectSettings.set_setting("rendering/scaling_3d/scale", clamp(render_scale, 0.5, 1.0))
    settings_changed.emit()

func save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("video", "resolution", resolution)
    config.set_value("video", "window_mode", window_mode)
    config.set_value("video", "fullscreen", fullscreen)
    config.set_value("video", "borderless", borderless)
    config.set_value("video", "vsync_enabled", vsync_enabled)
    config.set_value("video", "graphics_quality", graphics_quality)
    config.set_value("video", "render_scale", render_scale)
    config.set_value("video", "shadows_enabled", shadows_enabled)
    config.set_value("video", "anti_aliasing", anti_aliasing)
    config.set_value("input", "mouse_sensitivity", mouse_sensitivity)
    config.set_value("input", "controller_sensitivity", controller_sensitivity)
    config.set_value("input", "mobile_camera_sensitivity", mobile_camera_sensitivity)
    config.set_value("input", "invert_y", invert_y)
    config.set_value("audio", "master_volume", master_volume)
    config.set_value("audio", "music_volume", music_volume)
    config.set_value("audio", "effects_volume", effects_volume)
    config.set_value("audio", "voice_chat_enabled", voice_chat_enabled)
    config.set_value("mobile", "joystick_size", joystick_size)
    config.set_value("mobile", "touch_button_opacity", touch_button_opacity)
    config.set_value("mobile", "touch_controls_position", touch_controls_position)
    config.set_value("mobile", "vibration_enabled", vibration_enabled)
    config.set_value("mobile", "aim_assist_enabled", aim_assist_enabled)
    config.set_value("mobile", "force_mobile_ui_on_desktop", force_mobile_ui_on_desktop)
    config.set_value("developer", "debug_name_labels", debug_name_labels)
    config.set_value("developer", "debug_xray_enabled", debug_xray_enabled)
    _save_keybinds(config)
    var error := config.save(SAVE_PATH)
    if error != OK:
        push_warning("Lokale instellingen konden niet worden opgeslagen (%s)." % error)

func load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return
    _load_safe_values(config)
    _load_keybinds(config)

func set_value(key: String, value: Variant, persist := true) -> void:
    match key:
        "resolution":
            if value is Vector2i:
                resolution = value
        "window_mode":
            if str(value) in ["windowed", "borderless", "fullscreen"]:
                window_mode = str(value)
        "fullscreen":
            if value is bool:
                window_mode = "fullscreen" if value else "windowed"
        "borderless":
            if value is bool:
                window_mode = "borderless" if value else "windowed"
        "vsync_enabled":
            vsync_enabled = bool(value)
        "graphics_quality":
            if str(value) in ["Laag", "Middel", "Hoog"]:
                graphics_quality = str(value)
        "render_scale":
            render_scale = clamp(float(value), 0.5, 1.0)
        "shadows_enabled":
            shadows_enabled = bool(value)
        "anti_aliasing":
            anti_aliasing = str(value)
        "mouse_sensitivity":
            mouse_sensitivity = clamp(float(value), 0.0005, 0.01)
        "controller_sensitivity":
            controller_sensitivity = clamp(float(value), 0.5, 6.0)
        "mobile_camera_sensitivity":
            mobile_camera_sensitivity = clamp(float(value), 0.25, 2.5)
        "invert_y":
            invert_y = bool(value)
        "master_volume":
            master_volume = clamp(float(value), 0.0, 1.0)
        "music_volume":
            music_volume = clamp(float(value), 0.0, 1.0)
        "effects_volume":
            effects_volume = clamp(float(value), 0.0, 1.0)
        "voice_chat_enabled":
            voice_chat_enabled = bool(value)
        "joystick_size":
            joystick_size = clamp(float(value), 0.7, 1.5)
        "touch_button_opacity":
            touch_button_opacity = clamp(float(value), 0.25, 1.0)
        "touch_controls_position":
            touch_controls_position = str(value)
        "vibration_enabled":
            vibration_enabled = bool(value)
        "aim_assist_enabled":
            aim_assist_enabled = bool(value)
        "force_mobile_ui_on_desktop":
            force_mobile_ui_on_desktop = bool(value)
        "debug_name_labels":
            debug_name_labels = bool(value)
        "debug_xray_enabled":
            debug_xray_enabled = bool(value)
        _:
            push_warning("Onbekende instelling: %s" % key)
            return
    apply_settings()
    if persist:
        save_settings()

func restore_defaults() -> void:
    resolution = DEFAULT_RESOLUTION
    window_mode = "windowed"
    fullscreen = false
    borderless = false
    vsync_enabled = true
    graphics_quality = DEFAULT_GRAPHICS
    render_scale = 1.0
    shadows_enabled = true
    anti_aliasing = "2x"
    mouse_sensitivity = 0.0025
    controller_sensitivity = 2.8
    mobile_camera_sensitivity = 1.0
    invert_y = false
    master_volume = 0.85
    music_volume = 0.70
    effects_volume = 0.80
    voice_chat_enabled = false
    joystick_size = 1.0
    touch_button_opacity = 0.78
    touch_controls_position = "Standaard"
    vibration_enabled = true
    aim_assist_enabled = false
    force_mobile_ui_on_desktop = false
    debug_name_labels = false
    debug_xray_enabled = false
    var input_service := get_node_or_null("/root/InputService")
    if input_service:
        input_service.reset_bindings()
    apply_settings()
    save_settings()

func set_keybind(action: String, event: InputEvent) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, event)
    save_settings()

func _load_safe_values(config: ConfigFile) -> void:
    var loaded_resolution = config.get_value("video", "resolution", DEFAULT_RESOLUTION)
    if loaded_resolution is Vector2i and loaded_resolution.x >= 640 and loaded_resolution.y >= 360:
        resolution = loaded_resolution
    var loaded_mode := str(config.get_value("video", "window_mode", ""))
    if loaded_mode in ["windowed", "borderless", "fullscreen"]:
        window_mode = loaded_mode
    else:
        var old_fullscreen = config.get_value("video", "fullscreen", false)
        window_mode = "fullscreen" if old_fullscreen is bool and old_fullscreen else "windowed"
    graphics_quality = _safe_quality(config.get_value("video", "graphics_quality", DEFAULT_GRAPHICS))
    vsync_enabled = _safe_bool(config.get_value("video", "vsync_enabled", true), true)
    render_scale = clamp(_safe_float(config.get_value("video", "render_scale", 1.0), 1.0), 0.5, 1.0)
    shadows_enabled = _safe_bool(config.get_value("video", "shadows_enabled", true), true)
    anti_aliasing = str(config.get_value("video", "anti_aliasing", "2x"))
    mouse_sensitivity = clamp(_safe_float(config.get_value("input", "mouse_sensitivity", 0.0025), 0.0025), 0.0005, 0.01)
    controller_sensitivity = clamp(_safe_float(config.get_value("input", "controller_sensitivity", 2.8), 2.8), 0.5, 6.0)
    mobile_camera_sensitivity = clamp(_safe_float(config.get_value("input", "mobile_camera_sensitivity", 1.0), 1.0), 0.25, 2.5)
    invert_y = _safe_bool(config.get_value("input", "invert_y", false), false)
    master_volume = clamp(_safe_float(config.get_value("audio", "master_volume", 0.85), 0.85), 0.0, 1.0)
    music_volume = clamp(_safe_float(config.get_value("audio", "music_volume", 0.70), 0.70), 0.0, 1.0)
    effects_volume = clamp(_safe_float(config.get_value("audio", "effects_volume", 0.80), 0.80), 0.0, 1.0)
    voice_chat_enabled = _safe_bool(config.get_value("audio", "voice_chat_enabled", false), false)
    joystick_size = clamp(_safe_float(config.get_value("mobile", "joystick_size", 1.0), 1.0), 0.7, 1.5)
    touch_button_opacity = clamp(_safe_float(config.get_value("mobile", "touch_button_opacity", 0.78), 0.78), 0.25, 1.0)
    touch_controls_position = str(config.get_value("mobile", "touch_controls_position", "Standaard"))
    vibration_enabled = _safe_bool(config.get_value("mobile", "vibration_enabled", true), true)
    aim_assist_enabled = _safe_bool(config.get_value("mobile", "aim_assist_enabled", false), false)
    force_mobile_ui_on_desktop = _safe_bool(config.get_value("mobile", "force_mobile_ui_on_desktop", false), false)
    debug_name_labels = _safe_bool(config.get_value("developer", "debug_name_labels", false), false)
    debug_xray_enabled = _safe_bool(config.get_value("developer", "debug_xray_enabled", false), false)

func _save_keybinds(config: ConfigFile) -> void:
    var input_service := get_node_or_null("/root/InputService")
    var actions: Array = input_service.DEFAULT_ACTIONS if input_service else []
    for action in actions:
        var serialized: Array = []
        for event in InputMap.action_get_events(action):
            var data := _serialize_event(event)
            if not data.is_empty():
                serialized.append(data)
        config.set_value("keybinds", action, JSON.stringify(serialized))

func _load_keybinds(config: ConfigFile) -> void:
    if not config.has_section("keybinds"):
        return
    var input_service := get_node_or_null("/root/InputService")
    var actions: Array = input_service.DEFAULT_ACTIONS if input_service else []
    for action in actions:
        var raw := str(config.get_value("keybinds", action, ""))
        var parsed = JSON.parse_string(raw)
        if not parsed is Array or parsed.is_empty():
            continue
        InputMap.action_erase_events(action)
        for data in parsed:
            var event := _deserialize_event(data)
            if event:
                InputMap.action_add_event(action, event)

func _serialize_event(event: InputEvent) -> Dictionary:
    if event is InputEventKey:
        return {"type": "key", "physical": event.physical_keycode, "key": event.keycode, "shift": event.shift_pressed, "ctrl": event.ctrl_pressed, "alt": event.alt_pressed}
    if event is InputEventMouseButton:
        return {"type": "mouse", "button": event.button_index}
    return {}

func _deserialize_event(data: Variant) -> InputEvent:
    if not data is Dictionary:
        return null
    if data.get("type", "") == "key":
        var key := InputEventKey.new()
        key.physical_keycode = int(data.get("physical", 0))
        key.keycode = int(data.get("key", 0))
        key.shift_pressed = bool(data.get("shift", false))
        key.ctrl_pressed = bool(data.get("ctrl", false))
        key.alt_pressed = bool(data.get("alt", false))
        return key
    if data.get("type", "") == "mouse":
        var mouse := InputEventMouseButton.new()
        mouse.button_index = int(data.get("button", MOUSE_BUTTON_LEFT)) as MouseButton
        return mouse
    return null

func _safe_bool(value: Variant, fallback: bool) -> bool:
    return value if value is bool else fallback

func _safe_float(value: Variant, fallback: float) -> float:
    return float(value) if value is int or value is float else fallback

func _safe_quality(value: Variant) -> String:
    return str(value) if str(value) in ["Laag", "Middel", "Hoog"] else DEFAULT_GRAPHICS

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
    var bus_index := AudioServer.get_bus_index(bus_name)
    if bus_index == -1:
        return
    var clamped: float = clampf(linear_value, 0.0, 1.0)
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
