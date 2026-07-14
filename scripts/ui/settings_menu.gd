extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")
const MAIN_MENU_SCENE := "res://scenes/menus/main_menu.tscn"

var waiting_for_action := ""
var action_buttons: Dictionary = {}

func _ready() -> void:
    if not _is_logged_in():
        call_deferred("_go_to_login")
        return
    var cursor := get_node_or_null("/root/CursorManager")
    if cursor:
        cursor.set_mode(cursor.CursorMode.UI)
    UI_STYLE.apply_theme(self)
    _build()

func _unhandled_input(event: InputEvent) -> void:
    if waiting_for_action.is_empty():
        return
    if event is InputEventKey and event.pressed and not event.echo:
        _finish_keybind(event)
    elif event is InputEventMouseButton and event.pressed:
        _finish_keybind(event)

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color(0.025, 0.032, 0.055)
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 38)
    margin.add_theme_constant_override("margin_top", 30)
    margin.add_theme_constant_override("margin_right", 38)
    margin.add_theme_constant_override("margin_bottom", 30)
    add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var title := Label.new()
    title.text = "INSTELLINGEN"
    UI_STYLE.title(title, 38)
    column.add_child(title)

    var tabs := TabContainer.new()
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(tabs)
    _build_video_tab(tabs)
    _build_audio_tab(tabs)
    _build_controls_tab(tabs)
    _build_mobile_tab(tabs)
    _build_account_tab(tabs)

    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 10)
    column.add_child(footer)
    _add_button(footer, "Standaardinstellingen herstellen", _restore_defaults)
    _add_button(footer, "Terug", _back)

func _new_tab(parent: TabContainer, title: String) -> VBoxContainer:
    var scroll := ScrollContainer.new()
    scroll.name = title
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(scroll)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    box.custom_minimum_size = Vector2(720, 0)
    scroll.add_child(box)
    var header := Label.new()
    header.text = title
    header.add_theme_font_size_override("font_size", 24)
    header.add_theme_color_override("font_color", Color(0.35, 1.0, 0.86))
    box.add_child(header)
    return box

func _build_video_tab(parent: TabContainer) -> void:
    var box := _new_tab(parent, "Beeld")
    var settings := _settings()
    _add_option(box, "Resolutie", ["1280 x 720", "1600 x 900", "1920 x 1080"], _resolution_label(settings.resolution), func(index):
        var values := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
        settings.set_value("resolution", values[index])
    )
    _add_option(box, "Venstermodus", ["Windowed", "Borderless", "Fullscreen"], _window_label(settings.window_mode), func(index):
        settings.set_value("window_mode", ["windowed", "borderless", "fullscreen"][index])
    )
    _add_check(box, "VSync", settings.vsync_enabled, func(value): settings.set_value("vsync_enabled", value))
    _add_option(box, "Graphicskwaliteit", ["Laag", "Middel", "Hoog"], settings.graphics_quality, func(index):
        settings.set_value("graphics_quality", ["Laag", "Middel", "Hoog"][index])
    )
    _add_slider(box, "Render scale", settings.render_scale, 0.5, 1.0, 0.05, "render_scale")
    _add_check(box, "Schaduwen", settings.shadows_enabled, func(value): settings.set_value("shadows_enabled", value))
    _add_option(box, "Anti-aliasing", ["Uit", "2x", "4x"], settings.anti_aliasing, func(index):
        settings.set_value("anti_aliasing", ["Uit", "2x", "4x"][index])
    )

func _build_audio_tab(parent: TabContainer) -> void:
    var box := _new_tab(parent, "Audio")
    var settings := _settings()
    _add_slider(box, "Mastervolume", settings.master_volume, 0.0, 1.0, 0.01, "master_volume")
    _add_slider(box, "Muziek", settings.music_volume, 0.0, 1.0, 0.01, "music_volume")
    _add_slider(box, "Geluidseffecten", settings.effects_volume, 0.0, 1.0, 0.01, "effects_volume")
    _add_check(box, "Voicechat voorbereiden", settings.voice_chat_enabled, func(value): settings.set_value("voice_chat_enabled", value))
    var note := Label.new()
    note.text = "Voicechat is voorbereid voor een volgende multiplayerfase."
    note.add_theme_color_override("font_color", Color(0.62, 0.75, 0.84))
    box.add_child(note)

func _build_controls_tab(parent: TabContainer) -> void:
    var box := _new_tab(parent, "Besturing")
    var settings := _settings()
    _add_slider(box, "Muisgevoeligheid", settings.mouse_sensitivity, 0.0005, 0.01, 0.0005, "mouse_sensitivity")
    _add_slider(box, "Controllergevoeligheid", settings.controller_sensitivity, 0.5, 6.0, 0.1, "controller_sensitivity")
    _add_slider(box, "Mobiele cameragevoeligheid", settings.mobile_camera_sensitivity, 0.25, 2.5, 0.05, "mobile_camera_sensitivity")
    _add_check(box, "Y-as omkeren", settings.invert_y, func(value): settings.set_value("invert_y", value))

    var key_title := Label.new()
    key_title.text = "Keybinds"
    key_title.add_theme_font_size_override("font_size", 20)
    box.add_child(key_title)
    for action in ["move_forward", "move_backward", "move_left", "move_right", "jump", "sprint", "crouch", "action", "pause"]:
        _add_keybind_row(box, action)

func _build_mobile_tab(parent: TabContainer) -> void:
    var box := _new_tab(parent, "Mobiel")
    var settings := _settings()
    _add_slider(box, "Grootte joystick", settings.joystick_size, 0.7, 1.5, 0.05, "joystick_size")
    _add_slider(box, "Transparantie knoppen", settings.touch_button_opacity, 0.25, 1.0, 0.05, "touch_button_opacity")
    _add_option(box, "Positie touchcontrols", ["Standaard", "Links", "Rechts"], settings.touch_controls_position, func(index):
        settings.set_value("touch_controls_position", ["Standaard", "Links", "Rechts"][index])
    )
    _add_check(box, "Vibratie", settings.vibration_enabled, func(value): settings.set_value("vibration_enabled", value))
    _add_check(box, "Aim assist voorbereiden", settings.aim_assist_enabled, func(value): settings.set_value("aim_assist_enabled", value))
    var note := Label.new()
    note.text = "Aim assist geeft geen automatische targeting en blijft een eerlijke, voorbereidbare instelling."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_color_override("font_color", Color(0.62, 0.75, 0.84))
    box.add_child(note)

func _build_account_tab(parent: TabContainer) -> void:
    var box := _new_tab(parent, "Account")
    var session := get_node_or_null("/root/SessionManager")
    var name: String = str(session.display_name) if session and not session.display_name.is_empty() else "Onbekend"
    var email: String = str(session.email) if session else "Onbekend"
    var info := Label.new()
    info.text = "Gebruikersnaam: %s\nE-mailadres: %s" % [name, email]
    info.add_theme_color_override("font_color", Color(0.84, 0.92, 0.96))
    box.add_child(info)
    _add_button(box, "Uitloggen", _logout)

func _add_option(parent: VBoxContainer, label_text: String, options: Array[String], selected: String, callback: Callable) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    parent.add_child(row)
    var label := Label.new()
    label.text = label_text
    label.custom_minimum_size = Vector2(250, 38)
    row.add_child(label)
    var selector := OptionButton.new()
    selector.custom_minimum_size = Vector2(250, 38)
    for option in options:
        selector.add_item(option)
    var index := options.find(selected)
    selector.select(max(index, 0))
    selector.item_selected.connect(callback)
    row.add_child(selector)

func _add_check(parent: VBoxContainer, label_text: String, value: bool, callback: Callable) -> void:
    var check := CheckButton.new()
    check.text = label_text
    check.button_pressed = value
    check.toggled.connect(callback)
    parent.add_child(check)

func _add_slider(parent: VBoxContainer, label_text: String, value: float, minimum: float, maximum: float, step: float, key: String) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    parent.add_child(row)
    var label := Label.new()
    label.text = label_text
    label.custom_minimum_size = Vector2(250, 38)
    row.add_child(label)
    var slider := HSlider.new()
    slider.min_value = minimum
    slider.max_value = maximum
    slider.step = step
    slider.value = value
    slider.custom_minimum_size = Vector2(300, 28)
    row.add_child(slider)
    var value_label := Label.new()
    value_label.text = "%.2f" % value
    value_label.custom_minimum_size = Vector2(72, 38)
    row.add_child(value_label)
    var settings := _settings()
    slider.value_changed.connect(func(next_value: float):
        value_label.text = "%.2f" % next_value
        settings.set_value(key, next_value)
    )

func _add_keybind_row(parent: VBoxContainer, action: String) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    parent.add_child(row)
    var label := Label.new()
    label.text = _action_display_name(action)
    label.custom_minimum_size = Vector2(250, 38)
    row.add_child(label)
    var button := Button.new()
    button.text = _action_label(action)
    button.custom_minimum_size = Vector2(250, 38)
    button.pressed.connect(func(): _wait_for_key(action))
    row.add_child(button)
    action_buttons[action] = button

func _add_button(parent: Container, text: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(190, 42)
    button.add_theme_stylebox_override("normal", UI_STYLE.button())
    button.add_theme_stylebox_override("hover", UI_STYLE.button(Color(0.12, 0.25, 0.24), Color(0.18, 0.95, 0.72)))
    button.pressed.connect(callback)
    parent.add_child(button)

func _wait_for_key(action: String) -> void:
    waiting_for_action = action
    action_buttons[action].text = "Druk een toets..."

func _finish_keybind(event: InputEvent) -> void:
    var action := waiting_for_action
    waiting_for_action = ""
    var settings := _settings()
    settings.set_keybind(action, event)
    action_buttons[action].text = _action_label(action)
    get_viewport().set_input_as_handled()

func _action_label(action: String) -> String:
    var events := InputMap.action_get_events(action)
    return events[0].as_text() if not events.is_empty() else "Niet ingesteld"

func _action_display_name(action: String) -> String:
    var names := {
        "move_forward": "Vooruit",
        "move_backward": "Achteruit",
        "move_left": "Links",
        "move_right": "Rechts",
        "jump": "Springen",
        "sprint": "Sprinten",
        "crouch": "Hurken",
        "action": "Actie / scanner",
        "pause": "Pauze"
    }
    return names.get(action, action)

func _restore_defaults() -> void:
    _settings().restore_defaults()
    get_tree().reload_current_scene()

func _back() -> void:
    var game_state = get_node_or_null("/root/GameState")
    if game_state and game_state.current_state == game_state.State.PAUSED:
        queue_free()
        return
    _open_scene(MAIN_MENU_SCENE, false)

func _logout() -> void:
    var session := get_node_or_null("/root/SessionManager")
    if session:
        session.logout()
    _go_to_login()

func _open_scene(path: String, use_loading: bool) -> void:
    var manager := get_node_or_null("/root/SceneManager")
    if manager:
        manager.change_scene(path, use_loading)
    else:
        get_tree().change_scene_to_file(path)

func _go_to_login() -> void:
    _open_scene("res://scenes/login_menu.tscn", false)

func _is_logged_in() -> bool:
    var session := get_node_or_null("/root/SessionManager")
    return session != null and session.is_logged_in()

func _settings() -> Node:
    return get_node_or_null("/root/SettingsService")

func _resolution_label(value: Vector2i) -> String:
    return "%d x %d" % [value.x, value.y]

func _window_label(value: String) -> String:
    match value:
        "borderless":
            return "Borderless"
        "fullscreen":
            return "Fullscreen"
        _:
            return "Windowed"
