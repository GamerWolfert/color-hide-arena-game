extends Control

const UIStyle := preload("res://scripts/ui/ui_style.gd")
const LOGIN_SCENE := "res://scenes/login_menu.tscn"
const SETTINGS_SCENE := "res://scenes/menus/settings_menu.tscn"
const PROFILE_SCENE := "res://scenes/menus/profile_menu.tscn"
const TRAINING_SCENE := "res://scenes/gameplay/TrainingArena.tscn"

func _ready() -> void:
    if not _is_logged_in():
        _go_to_login()
        return
    var game_state = get_node_or_null("/root/GameState")
    if game_state:
        game_state.set_state(game_state.State.MAIN_MENU)
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    UIStyle.apply_theme(self)
    _build()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color(0.025, 0.035, 0.06)
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var accent := ColorRect.new()
    accent.color = Color(0.05, 0.18, 0.19, 0.65)
    accent.set_anchors_preset(Control.PRESET_FULL_RECT)
    accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(accent)

    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 44)
    margin.add_theme_constant_override("margin_top", 36)
    margin.add_theme_constant_override("margin_right", 44)
    margin.add_theme_constant_override("margin_bottom", 36)
    add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 34)
    margin.add_child(row)

    var menu_panel := PanelContainer.new()
    menu_panel.custom_minimum_size = Vector2(430, 0)
    menu_panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.045, 0.06, 0.10, 0.97), Color(0.14, 0.86, 0.78, 0.9)))
    row.add_child(menu_panel)

    var menu := VBoxContainer.new()
    menu.add_theme_constant_override("separation", 10)
    menu_panel.add_child(menu)

    var title := Label.new()
    title.text = "MECCHA CHAMELEON"
    UIStyle.title(title, 34)
    menu.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Kies je volgende camouflage-ronde."
    subtitle.add_theme_color_override("font_color", Color(0.72, 0.92, 0.88))
    menu.add_child(subtitle)

    var divider := HSeparator.new()
    menu.add_child(divider)

    _add_button(menu, "Spelen", func(): _start_training(), false)
    _add_button(menu, "Training", func(): _start_training(), false)
    var multiplayer := _add_button(menu, "Multiplayer", func(): _show_notice("Multiplayer wordt voorbereid."), true)
    multiplayer.tooltip_text = "Online spelen wordt voorbereid."
    _add_button(menu, "Profiel", func(): _open_scene(PROFILE_SCENE, false), false)
    _add_button(menu, "Instellingen", func(): _open_scene(SETTINGS_SCENE, false), false)
    _add_button(menu, "Uitloggen", func(): _logout(), false)
    var device = get_node_or_null("/root/DeviceService")
    if device == null or device.is_desktop():
        _add_button(menu, "Stoppen", func(): get_tree().quit(), false)

    var info_panel := PanelContainer.new()
    info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.06, 0.075, 0.12, 0.90), Color(0.52, 0.24, 0.92, 0.9)))
    row.add_child(info_panel)

    var info := VBoxContainer.new()
    info.add_theme_constant_override("separation", 14)
    info_panel.add_child(info)
    var welcome := Label.new()
    welcome.text = "WELKOM TERUG"
    UIStyle.title(welcome, 28)
    info.add_child(welcome)
    var session = get_node_or_null("/root/SessionManager")
    var player_name: String = str(session.display_name) if session and not session.display_name.is_empty() else "Speler"
    var account := Label.new()
    account.text = "%s\n\nKopieer kleuren, lees de omgeving en blijf onzichtbaar." % player_name
    account.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    account.add_theme_color_override("font_color", Color(0.9, 0.95, 0.94))
    info.add_child(account)
    var device_label := Label.new()
    device_label.text = "Apparaat: %s" % (device.get_summary() if device else "Onbekend")
    device_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    device_label.add_theme_color_override("font_color", Color(0.65, 0.9, 0.98))
    info.add_child(device_label)
    var note := Label.new()
    note.text = "Training is offline speelbaar. Besturing en beeldinstellingen worden lokaal bewaard."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
    info.add_child(note)

func _add_button(parent: VBoxContainer, text: String, callback: Callable, disabled: bool) -> Button:
    var button := Button.new()
    button.text = text
    button.disabled = disabled
    button.custom_minimum_size = Vector2(320, 44)
    button.add_theme_stylebox_override("normal", UIStyle.button())
    button.add_theme_stylebox_override("hover", UIStyle.button(Color(0.12, 0.25, 0.24), Color(0.18, 0.95, 0.72)))
    button.add_theme_stylebox_override("pressed", UIStyle.button(Color(0.20, 0.16, 0.10), Color(1.0, 0.82, 0.25)))
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _start_training() -> void:
    var game_state = get_node_or_null("/root/GameState")
    if game_state:
        game_state.start_training()
    else:
        _open_scene(TRAINING_SCENE, true)

func _show_notice(message: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "Meccha Chameleon"
    dialog.dialog_text = message
    add_child(dialog)
    dialog.popup_centered()

func _open_scene(path: String, use_loading: bool) -> void:
    var manager := get_node_or_null("/root/SceneManager")
    if manager:
        manager.change_scene(path, use_loading)
    else:
        get_tree().change_scene_to_file(path)

func _logout() -> void:
    var session := get_node_or_null("/root/SessionManager")
    if session:
        session.logout()
    _go_to_login()

func _go_to_login() -> void:
    var manager := get_node_or_null("/root/SceneManager")
    if manager:
        manager.change_scene(LOGIN_SCENE, false)
    else:
        get_tree().change_scene_to_file(LOGIN_SCENE)

func _is_logged_in() -> bool:
    var session := get_node_or_null("/root/SessionManager")
    return session != null and session.is_logged_in()
