extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")

func _ready() -> void:
    if not _is_logged_in():
        call_deferred("_open_scene", "res://scenes/login_menu.tscn")
        return
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    UI_STYLE.apply_theme(self)
    _build()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _open_scene("res://scenes/menus/main_menu.tscn")
        get_viewport().set_input_as_handled()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color(0.018, 0.028, 0.06)
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.offset_left = -290.0
    panel.offset_top = -190.0
    panel.offset_right = 290.0
    panel.offset_bottom = 190.0
    panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.04, 0.05, 0.11, 0.96), Color(0.18, 0.90, 0.80, 0.9)))
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 12)
    panel.add_child(box)
    var title := Label.new()
    title.text = "PRIVATE LOBBY"
    UI_STYLE.title(title, 32)
    box.add_child(title)
    var info := Label.new()
    info.name = "LobbyInfo"
    info.text = "Private lobbies zijn voorbereid. Netwerkverbindingen worden nog niet nagebootst."
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_color_override("font_color", Color(0.78, 0.87, 0.96))
    box.add_child(info)
    var code := LineEdit.new()
    code.placeholder_text = "Lobbycode"
    code.max_length = 12
    box.add_child(code)
    var create := _button("Lobby maken", func(): info.text = "Lobby maken is beschikbaar zodra de netwerksessie is toegevoegd.")
    box.add_child(create)
    box.add_child(_button("Joinen", func(): info.text = "Voer een lobbycode in. Verbinden wordt later toegevoegd." if code.text.strip_edges().is_empty() else "Verbinden met lobby is nog niet beschikbaar."))
    box.add_child(_button("Terug", func(): _open_scene("res://scenes/menus/main_menu.tscn")))
    create.grab_focus()

func _button(text_value: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(230.0, 42.0)
    button.add_theme_stylebox_override("normal", UI_STYLE.button())
    button.pressed.connect(callback)
    return button

func _open_scene(path: String) -> void:
    var manager := get_node_or_null("/root/SceneManager")
    if manager:
        manager.change_scene(path, false)
    else:
        get_tree().change_scene_to_file(path)

func _is_logged_in() -> bool:
    var session := get_node_or_null("/root/SessionManager")
    return session != null and session.is_logged_in()
