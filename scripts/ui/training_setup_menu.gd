extends Control

const UIStyle := preload("res://scripts/ui/ui_style.gd")
const TRAINING_SCENE := "res://scenes/gameplay/TrainingArena.tscn"

var _transitioning := false

func _ready() -> void:
    if not _is_logged_in():
        call_deferred("_open_scene", "res://scenes/login_menu.tscn", false)
        return
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    UIStyle.apply_theme(self)
    _build()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _open_scene("res://scenes/menus/main_menu.tscn", false)
        get_viewport().set_input_as_handled()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color(0.018, 0.028, 0.06)
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.offset_left = -280.0
    panel.offset_top = -180.0
    panel.offset_right = 280.0
    panel.offset_bottom = 180.0
    panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.04, 0.07, 0.11, 0.96), Color(0.18, 0.90, 0.78, 0.9)))
    add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 14)
    panel.add_child(box)
    var title := Label.new()
    title.text = "TRAINING"
    UIStyle.title(title, 36)
    box.add_child(title)
    var description := Label.new()
    description.text = "Train offline in de kleurrijke arena. Leer kleuren kopieren, verstoppen en scannen."
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_color_override("font_color", Color(0.80, 0.90, 0.97))
    box.add_child(description)
    var start := _button("Start training", _start_training)
    box.add_child(start)
    box.add_child(_button("Terug", func(): _open_scene("res://scenes/menus/main_menu.tscn", false)))
    start.grab_focus()

func _button(text_value: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(240.0, 46.0)
    button.add_theme_stylebox_override("normal", UIStyle.button())
    button.add_theme_stylebox_override("hover", UIStyle.button(Color(0.10, 0.20, 0.24), Color(0.62, 0.30, 0.95)))
    button.pressed.connect(callback)
    return button

func _start_training() -> void:
    if _transitioning:
        return
    _transitioning = true
    _open_scene(TRAINING_SCENE, true)

func _open_scene(path: String, use_loading: bool) -> void:
    var manager := get_node_or_null("/root/SceneManager")
    if manager:
        manager.change_scene(path, use_loading, "Training wordt geladen")
    else:
        get_tree().change_scene_to_file(path)

func _is_logged_in() -> bool:
    var session := get_node_or_null("/root/SessionManager")
    return session != null and session.is_logged_in()
