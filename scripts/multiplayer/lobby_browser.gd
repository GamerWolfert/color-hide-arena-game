extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")

func _ready() -> void:
    if not _is_logged_in():
        call_deferred("_open_scene", "res://scenes/login_menu.tscn")
        return
    var cursor := get_node_or_null("/root/CursorManager")
    if cursor:
        cursor.set_mode(cursor.CursorMode.UI)
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
    panel.offset_left = -300.0
    panel.offset_top = -185.0
    panel.offset_right = 300.0
    panel.offset_bottom = 185.0
    panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.04, 0.05, 0.11, 0.96), Color(0.58, 0.28, 0.94, 0.9)))
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    panel.add_child(box)
    var title := Label.new()
    title.text = "MULTIPLAYER"
    UI_STYLE.title(title, 34)
    box.add_child(title)
    var status := Label.new()
    status.name = "LobbyStatus"
    status.text = "Lobbybrowser wordt voorbereid. Er zijn nog geen live servers verbonden."
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.add_theme_color_override("font_color", Color(0.78, 0.87, 0.96))
    status.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(status)
    var refresh := _button("Ververs lijst", func(): status.text = "Geen servers beschikbaar. Netwerkfunctionaliteit wordt later toegevoegd.")
    box.add_child(refresh)
    box.add_child(_button("Terug", func(): _open_scene("res://scenes/menus/main_menu.tscn")))
    refresh.grab_focus()

func _button(text_value: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(230.0, 44.0)
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
