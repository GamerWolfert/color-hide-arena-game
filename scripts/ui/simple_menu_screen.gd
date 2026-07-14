extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")

@export var screen_title := "Meccha Chameleon"
@export_multiline var screen_body := "Dit scherm wordt voorbereid."

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
    panel.offset_left = -270.0
    panel.offset_top = -170.0
    panel.offset_right = 270.0
    panel.offset_bottom = 170.0
    panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.04, 0.06, 0.11, 0.96), Color(0.22, 0.88, 0.80, 0.9)))
    add_child(panel)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 16)
    panel.add_child(content)
    var title := Label.new()
    title.text = screen_title
    UI_STYLE.title(title, 34)
    content.add_child(title)
    var body := Label.new()
    body.text = screen_body
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_color_override("font_color", Color(0.78, 0.87, 0.96))
    content.add_child(body)
    var back := Button.new()
    back.text = "Terug"
    back.custom_minimum_size = Vector2(170.0, 42.0)
    back.add_theme_stylebox_override("normal", UI_STYLE.button())
    back.pressed.connect(func(): _open_scene("res://scenes/menus/main_menu.tscn"))
    content.add_child(back)
    back.grab_focus()

func _open_scene(path: String) -> void:
    var manager := get_node_or_null("/root/SceneManager")
    if manager:
        manager.change_scene(path, false)
    else:
        get_tree().change_scene_to_file(path)

func _is_logged_in() -> bool:
    var session := get_node_or_null("/root/SessionManager")
    return session != null and session.is_logged_in()
