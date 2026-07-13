extends CanvasLayer

const UIStyle := preload("res://scripts/ui/ui_style.gd")

signal restart_requested

var settings_panel: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_state(game_state.State.PAUSED if visible else game_state.previous_state)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -190
	panel.offset_top = -170
	panel.offset_right = 190
	panel.offset_bottom = 170
	panel.add_theme_stylebox_override("panel", UIStyle.panel())
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Pauze"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyle.title(title, 32)
	box.add_child(title)

	_add_button(box, "Doorgaan", toggle_pause)
	_add_button(box, "Instellingen", _open_settings)
	_add_button(box, "Opnieuw starten", _restart)
	_add_button(box, "Terug naar hoofdmenu", _go_to_main_menu)

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 44)
	button.add_theme_stylebox_override("normal", UIStyle.button())
	button.pressed.connect(callback)
	parent.add_child(button)

func _open_settings() -> void:
	if settings_panel and is_instance_valid(settings_panel):
		settings_panel.queue_free()
	var scene := load("res://scenes/menus/settings_menu.tscn") as PackedScene
	settings_panel = scene.instantiate()
	add_child(settings_panel)

func _restart() -> void:
	toggle_pause()
	restart_requested.emit()

func _go_to_main_menu() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.go_to_main_menu()
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
