extends Control

const UIStyle := preload("res://scripts/ui/ui_style.gd")

var action_buttons := {}
var waiting_for_action := ""

func _ready() -> void:
	UIStyle.apply_theme(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if waiting_for_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		InputMap.action_erase_events(waiting_for_action)
		InputMap.action_add_event(waiting_for_action, event)
		action_buttons[waiting_for_action].text = _action_label(waiting_for_action)
		waiting_for_action = ""
		get_viewport().set_input_as_handled()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.045, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Instellingen"
	UIStyle.title(title, 38)
	root.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)

	_add_resolution(grid)
	_add_fullscreen(grid)
	_add_quality(grid)
	var settings = _settings()
	_add_slider(grid, "Muisgevoeligheid", settings.mouse_sensitivity, 0.001, 0.006, func(v): settings.mouse_sensitivity = v)
	_add_slider(grid, "Mastervolume", settings.master_volume, 0.0, 1.0, func(v): settings.master_volume = v)
	_add_slider(grid, "Muziekvolume", settings.music_volume, 0.0, 1.0, func(v): settings.music_volume = v)
	_add_slider(grid, "Effectenvolume", settings.effects_volume, 0.0, 1.0, func(v): settings.effects_volume = v)

	var key_title := Label.new()
	key_title.text = "Keybinds"
	key_title.add_theme_font_size_override("font_size", 24)
	root.add_child(key_title)

	var keys := GridContainer.new()
	keys.columns = 2
	keys.add_theme_constant_override("h_separation", 18)
	keys.add_theme_constant_override("v_separation", 8)
	root.add_child(keys)
	for action in ["move_forward", "move_backward", "move_left", "move_right", "jump", "sprint", "crouch", "action", "pause"]:
		var label := Label.new()
		label.text = action
		keys.add_child(label)
		var button := Button.new()
		button.text = _action_label(action)
		button.custom_minimum_size = Vector2(220, 36)
		button.pressed.connect(func(a: String = action): _wait_for_key(a))
		action_buttons[action] = button
		keys.add_child(button)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	_add_footer_button(footer, "Opslaan", _save)
	_add_footer_button(footer, "Terug", _back)

func _add_resolution(parent: GridContainer) -> void:
	parent.add_child(_label("Resolutie"))
	var options := OptionButton.new()
	var settings = _settings()
	var values := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
	for value in values:
		options.add_item("%dx%d" % [value.x, value.y])
		if value == settings.resolution:
			options.select(options.item_count - 1)
	options.item_selected.connect(func(index): settings.resolution = values[index])
	parent.add_child(options)

func _add_fullscreen(parent: GridContainer) -> void:
	parent.add_child(_label("Fullscreen"))
	var check := CheckButton.new()
	var settings = _settings()
	check.button_pressed = settings.fullscreen
	check.toggled.connect(func(value): settings.fullscreen = value)
	parent.add_child(check)

func _add_quality(parent: GridContainer) -> void:
	parent.add_child(_label("Graphics"))
	var options := OptionButton.new()
	var settings = _settings()
	for quality in ["Laag", "Middel", "Hoog"]:
		options.add_item(quality)
		if quality == settings.graphics_quality:
			options.select(options.item_count - 1)
	options.item_selected.connect(func(index): settings.graphics_quality = options.get_item_text(index))
	parent.add_child(options)

func _add_slider(parent: GridContainer, label_text: String, value: float, min_value: float, max_value: float, setter: Callable) -> void:
	parent.add_child(_label(label_text))
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.001
	slider.value = value
	slider.custom_minimum_size = Vector2(340, 28)
	slider.value_changed.connect(func(v): setter.call(v))
	parent.add_child(slider)

func _add_footer_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 42)
	button.add_theme_stylebox_override("normal", UIStyle.button())
	button.pressed.connect(callback)
	parent.add_child(button)

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label

func _wait_for_key(action: String) -> void:
	waiting_for_action = action
	action_buttons[action].text = "Druk een toets..."

func _action_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	return events[0].as_text() if events.size() > 0 else "Niet ingesteld"

func _save() -> void:
	var settings = _settings()
	settings.apply_settings()
	settings.save_settings()

func _back() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.current_state == game_state.State.PAUSED:
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")

func _settings():
	var settings = get_node_or_null("/root/SettingsService")
	if settings:
		return settings
	return preload("res://scripts/services/settings_service.gd").new()
