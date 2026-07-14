extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")

func _ready() -> void:
	if not _is_logged_in():
		call_deferred("_go_to_login")
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	UI_STYLE.apply_theme(self)
	_build()

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.025, 0.032, 0.055)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 42)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var title := Label.new()
	title.text = "PROFIEL"
	UI_STYLE.title(title, 40)
	column.add_child(title)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.055, 0.075, 0.12, 0.96), Color(0.22, 0.86, 0.78, 0.9)))
	panel.custom_minimum_size = Vector2(420, 230)
	column.add_child(panel)

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 12)
	panel.add_child(details)
	var session = _session()
	var username: String = str(session.display_name) if session and not session.display_name.is_empty() else "Camouflage-speler"
	var email: String = str(session.email) if session else "Onbekend"
	var user_label := Label.new()
	user_label.text = "Speler\n%s" % username
	user_label.add_theme_font_size_override("font_size", 24)
	details.add_child(user_label)
	details.add_child(_detail("E-mailadres", email))
	details.add_child(_detail("Platform", _device_summary()))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	column.add_child(footer)
	_add_button(footer, "Terug", _back)
	_add_button(footer, "Uitloggen", _logout)

func _detail(label_text: String, value: String) -> Label:
	var label := Label.new()
	label.text = "%s: %s" % [label_text, value]
	label.add_theme_color_override("font_color", Color(0.75, 0.88, 0.94))
	return label

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 44)
	button.add_theme_stylebox_override("normal", UI_STYLE.button())
	button.add_theme_stylebox_override("hover", UI_STYLE.button(Color(0.12, 0.25, 0.24), Color(0.18, 0.95, 0.72)))
	button.pressed.connect(callback)
	parent.add_child(button)

func _back() -> void:
	_scene_manager().change_scene("res://scenes/menus/main_menu.tscn", false)

func _logout() -> void:
	var session := _session()
	if session:
		session.logout()
	_go_to_login()

func _go_to_login() -> void:
	var manager = _scene_manager()
	if manager:
		manager.change_scene("res://scenes/login_menu.tscn", false)
	else:
		get_tree().change_scene_to_file("res://scenes/login_menu.tscn")

func _is_logged_in() -> bool:
	var session := _session()
	return session != null and session.is_logged_in()

func _session() -> Node:
	return get_node_or_null("/root/SessionManager")

func _scene_manager() -> Node:
	return get_node_or_null("/root/SceneManager")

func _device_summary() -> String:
	var device := get_node_or_null("/root/DeviceService")
	return device.get_summary() if device else "Onbekend apparaat"
