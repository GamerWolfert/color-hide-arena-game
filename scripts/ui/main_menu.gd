extends Control

const UIStyle := preload("res://scripts/ui/ui_style.gd")

func _ready() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_state(game_state.State.MAIN_MENU)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	UIStyle.apply_theme(self)
	_build()

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.045, 0.06)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var camo := ColorRect.new()
	camo.color = Color(0.08, 0.22, 0.18, 0.68)
	camo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(camo)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 56)
	root.add_theme_constant_override("margin_top", 48)
	root.add_theme_constant_override("margin_right", 56)
	root.add_theme_constant_override("margin_bottom", 48)
	add_child(root)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 42)
	root.add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(470, 0)
	left.add_theme_constant_override("separation", 16)
	row.add_child(left)

	var title := Label.new()
	title.text = "COLOR HIDE ARENA"
	UIStyle.title(title, 44)
	left.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Kleurrijke camouflage, snelle rondes, slimme zoekers."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.95, 0.88))
	left.add_child(subtitle)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	left.add_child(buttons)

	_add_button(buttons, "Spelen", func(): _start_training())
	_add_button(buttons, "Training", func(): _start_training())
	_add_button(buttons, "Profiel", func(): _show_profile())
	_add_button(buttons, "Instellingen", func(): get_tree().change_scene_to_file("res://scenes/menus/SettingsMenu.tscn"))
	_add_button(buttons, "Uitloggen", func(): _logout())
	_add_button(buttons, "Stoppen", func(): get_tree().quit())

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.09, 0.10, 0.13, 0.86), Color(0.78, 0.24, 0.74, 0.9)))
	row.add_child(card)

	var info := Label.new()
	info.text = "Training build\n\nLeer muren scannen, kleuren kopieren en het tempo van de ronde lezen. Deze basis is klaar om later bots, multiplayer of extra maps te krijgen."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(420, 260)
	info.add_theme_color_override("font_color", Color(0.92, 0.95, 0.92))
	card.add_child(info)

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 48)
	button.add_theme_stylebox_override("normal", UIStyle.button())
	button.add_theme_stylebox_override("hover", UIStyle.button(Color(0.13, 0.24, 0.24), Color(0.18, 0.95, 0.72)))
	button.add_theme_stylebox_override("pressed", UIStyle.button(Color(0.20, 0.16, 0.10), Color(1.0, 0.82, 0.25)))
	button.pressed.connect(callback)
	parent.add_child(button)

func _show_profile() -> void:
	var session := get_node_or_null("/root/SessionManager")
	var account_email := "Niet ingelogd"
	if session != null and not session.email.is_empty():
		account_email = session.email
	var dialog := AcceptDialog.new()
	dialog.title = "Profiel"
	dialog.dialog_text = "Ingelogd als:\n" + account_email
	add_child(dialog)
	dialog.popup_centered()

func _logout() -> void:
	var session := get_node_or_null("/root/SessionManager")
	if session != null:
		session.logout()
	get_tree().change_scene_to_file("res://scenes/login_menu.tscn")

func _start_training() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.start_training()
	else:
		get_tree().change_scene_to_file("res://scenes/gameplay/TrainingArena.tscn")
