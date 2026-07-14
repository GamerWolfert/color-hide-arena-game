extends CanvasLayer

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")
const PaintModeScene := preload("res://scenes/ui/paint_mode_ui.tscn")
const PoseWheelScene := preload("res://scenes/ui/pose_wheel.tscn")
const RoundTimerScene := preload("res://scenes/ui/round_timer_hud.tscn")

var root: Control
var role_label: Label
var phase_label: Label
var timer_label: Label
var camo_label: Label
var camo_bar: ProgressBar
var part_label: Label
var pose_label: Label
var energy_label: Label
var hiders_label: Label
var counts_label: Label
var username_label: Label
var message_label: Label
var pulse: ColorRect
var message_timer: Timer
var tutorial_timer: Timer
var pulse_timer: Timer
var paint_ui: Control
var _player: Node
var _round_manager: Node
var _mobile_controls: Control
var _action_panel: PanelContainer
var _pose_wheel: Control
var _round_timer_ui: Control
var _tutorial_toast: PanelContainer
var _result_overlay: PanelContainer
var _result_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	var settings := get_node_or_null("/root/SettingsService")
	if settings and not settings.settings_changed.is_connected(_refresh_device_controls):
		settings.settings_changed.connect(_refresh_device_controls)
	_refresh_device_controls()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pose_menu"):
		_toggle_pose_menu()
		get_viewport().set_input_as_handled()

func bind_player(player: Node) -> void:
	_player = player
	var session := get_node_or_null("/root/SessionManager")
	if session and not session.display_name.is_empty():
		username_label.text = str(session.display_name)
	_connect_player_signal(player, "role_changed", _on_role_changed)
	_connect_player_signal(player, "color_sampled", _on_color_sampled)
	_connect_player_signal(player, "seeker_scanned", _on_scan)
	_connect_player_signal(player, "camouflage_changed", _on_camouflage_changed)
	_connect_player_signal(player, "scanner_fired", _on_scanner_fired)
	_connect_player_signal(player, "taunt_requested", _on_taunt)
	_connect_player_signal(player, "scanner_cooldown_changed", _on_scanner_cooldown)
	if paint_ui:
		paint_ui.bind_player(player)
	if player.get("is_hider") != null:
		_on_role_changed(player.is_hider)

func bind_round_manager(round_manager: Node) -> void:
	_round_manager = round_manager
	if _round_timer_ui and _round_timer_ui.has_method("bind_round_manager"):
		_round_timer_ui.bind_round_manager(round_manager)
	_connect_manager_signal(round_manager, "phase_changed", _on_phase_changed)
	_connect_manager_signal(round_manager, "timer_changed", _on_timer_changed)
	_connect_manager_signal(round_manager, "round_message", show_message)
	_connect_manager_signal(round_manager, "hider_count_changed", _on_hider_count_changed)
	_connect_manager_signal(round_manager, "role_counts_changed", _on_role_counts_changed)
	_connect_manager_signal(round_manager, "state_changed", _on_round_state_changed)
	if round_manager.has_signal("round_finished"):
		var finished_signal := Signal(round_manager, "round_finished")
		if not finished_signal.is_connected(_on_round_finished):
			finished_signal.connect(_on_round_finished)

func show_message(text: String) -> void:
	if not message_label or text.is_empty():
		return
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0
	message_timer.start()

func _build() -> void:
	root = Control.new()
	root.name = "GameplayOverlay"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 20
	add_child(root)
	_build_player_card()
	_round_timer_ui = RoundTimerScene.instantiate()
	root.add_child(_round_timer_ui)
	phase_label = _round_timer_ui.phase_label
	timer_label = _round_timer_ui.timer_label
	counts_label = _round_timer_ui.counts_label
	_build_action_panel()
	_build_toasts()
	_build_result_overlay()
	_create_crosshair()
	_pose_wheel = PoseWheelScene.instantiate()
	_pose_wheel.name = "PoseWheel"
	root.add_child(_pose_wheel)
	_pose_wheel.pose_selected.connect(func(_index: int, pose_name: String): show_message("Pose geselecteerd: %s" % pose_name))
	paint_ui = PaintModeScene.instantiate()
	paint_ui.name = "PaintModeUI"
	root.add_child(paint_ui)
	paint_ui.paint_mode_toggled.connect(_on_paint_mode_toggled)

func _build_player_card() -> void:
	var player_card := _panel(Control.PRESET_TOP_LEFT, Vector4(16, 16, 240, 160), Color(0.018, 0.035, 0.065, 0.82), Color(0.10, 0.86, 0.78, 0.76))
	player_card.name = "CompactPlayerCard"
	root.add_child(player_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	player_card.add_child(box)
	var game_label := _label("MECCHA CHAMELEON", 10)
	game_label.add_theme_color_override("font_color", Color(0.25, 0.98, 0.86))
	box.add_child(game_label)
	username_label = _label("Camouflage-speler", 15)
	box.add_child(username_label)
	role_label = _label("HIDER", 17)
	box.add_child(role_label)
	camo_label = _label("CAMOUFLAGE 0%", 11)
	box.add_child(camo_label)
	camo_bar = ProgressBar.new()
	camo_bar.max_value = 100.0
	camo_bar.show_percentage = false
	camo_bar.custom_minimum_size = Vector2(0, 6)
	camo_bar.add_theme_stylebox_override("background", _bar_style(Color(0.02, 0.06, 0.10, 0.95)))
	camo_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.12, 0.91, 0.76, 1.0)))
	box.add_child(camo_bar)
	part_label = _label("DEEL  Torso", 10)
	pose_label = _label("POSE  Normaal staan", 10)
	hiders_label = _label("HIDERS OVER  0/0", 10)
	box.add_child(part_label)
	box.add_child(pose_label)
	box.add_child(hiders_label)

func _build_action_panel() -> void:
	_action_panel = _panel(Control.PRESET_TOP_RIGHT, Vector4(-184, 72, -16, 258), Color(0.018, 0.035, 0.065, 0.76), Color(0.62, 0.25, 0.94, 0.72))
	_action_panel.name = "CompactActions"
	root.add_child(_action_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_action_panel.add_child(box)
	box.add_child(_action_button("Taunt", "taunt", _on_taunt_pressed, Color(0.64, 0.30, 0.95)))
	box.add_child(_action_button("Pose", "pose_menu", _toggle_pose_menu, Color(0.17, 0.88, 0.80)))
	box.add_child(_action_button("Paint", "paint_mode", _toggle_paint_mode, Color(0.17, 0.88, 0.80)))
	box.add_child(_action_button("Rotatie", "toggle_rotation_lock", _toggle_rotation_lock, Color(0.64, 0.30, 0.95)))
	box.add_child(_action_button("Pauze", "pause", _toggle_pause, Color(0.96, 0.70, 0.16)))
	energy_label = _label("ENERGIE 100", 10)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.visible = false
	box.add_child(energy_label)

func _build_toasts() -> void:
	message_label = _label("", 14)
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.offset_left = -260
	message_label.offset_top = 116
	message_label.offset_right = 260
	message_label.offset_bottom = 148
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	message_label.visible = false
	root.add_child(message_label)
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 2.5
	message_timer.timeout.connect(_fade_message)
	add_child(message_timer)
	_tutorial_toast = _panel(Control.PRESET_CENTER_BOTTOM, Vector4(-205, -58, 205, -20), Color(0.018, 0.035, 0.065, 0.82), Color(0.10, 0.82, 0.78, 0.62))
	_tutorial_toast.name = "TutorialToast"
	var tutorial_label := _label("WASD bewegen  |  Shift sprint  |  Spatie springen", 10)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_toast.add_child(tutorial_label)
	root.add_child(_tutorial_toast)
	tutorial_timer = Timer.new()
	tutorial_timer.one_shot = true
	tutorial_timer.wait_time = 5.0
	tutorial_timer.timeout.connect(_fade_tutorial)
	add_child(tutorial_timer)
	tutorial_timer.start()
	pulse_timer = Timer.new()
	pulse_timer.one_shot = true
	pulse_timer.wait_time = 0.16
	pulse_timer.timeout.connect(func(): pulse.visible = false)
	add_child(pulse_timer)

func _build_result_overlay() -> void:
	_result_overlay = _panel(Control.PRESET_CENTER, Vector4(-210, -105, 210, 105), Color(0.018, 0.035, 0.065, 0.96), Color(0.68, 0.30, 0.98, 0.95))
	_result_overlay.name = "RoundResultOverlay"
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	_result_overlay.add_child(box)
	var title := _label("RONDE AFGELOPEN", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.28, 0.96, 0.84))
	box.add_child(title)
	_result_label = _label("", 28)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_label)
	var subtitle := _label("Nieuwe ronde wordt voorbereid", 11)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	_result_overlay.visible = false
	root.add_child(_result_overlay)

func _fade_message() -> void:
	var tween := create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, 0.24)
	tween.tween_callback(func(): message_label.visible = false)

func _fade_tutorial() -> void:
	var tween := create_tween()
	tween.tween_property(_tutorial_toast, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func(): _tutorial_toast.visible = false)

func _create_crosshair() -> void:
	var crosshair := Control.new()
	crosshair.name = "Crosshair"
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -11
	crosshair.offset_top = -11
	crosshair.offset_right = 11
	crosshair.offset_bottom = 11
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	for rect in [Rect2(10, 0, 2, 7), Rect2(10, 15, 2, 7), Rect2(0, 10, 7, 2), Rect2(15, 10, 7, 2)]:
		var mark := ColorRect.new()
		mark.position = rect.position
		mark.size = rect.size
		mark.color = Color(0.98, 1.0, 0.94, 0.92)
		crosshair.add_child(mark)
	pulse = ColorRect.new()
	pulse.position = Vector2(4, 4)
	pulse.size = Vector2(14, 14)
	pulse.color = Color(0.2, 1.0, 0.75, 0.35)
	pulse.visible = false
	crosshair.add_child(pulse)

func _panel(preset: int, rect: Vector4, background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(preset)
	panel.offset_left = rect.x
	panel.offset_top = rect.y
	panel.offset_right = rect.z
	panel.offset_bottom = rect.w
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel(background, border))
	return panel

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

func _action_button(label_text: String, action: String, callback: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.name = "%sButton" % label_text
	button.text = "[%s]  %s" % [_action_key(action, "-"), label_text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(148, 27)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_stylebox_override("normal", UI_STYLE.button(Color(0.03, 0.07, 0.12, 0.90), Color(accent.r, accent.g, accent.b, 0.56)))
	button.add_theme_stylebox_override("hover", UI_STYLE.button(Color(0.10, 0.06, 0.17, 0.98), accent))
	button.add_theme_stylebox_override("pressed", UI_STYLE.button(Color(0.06, 0.18, 0.18, 1.0), Color(1.0, 0.82, 0.26)))
	button.mouse_entered.connect(func(): _set_cursor_hover(true))
	button.mouse_exited.connect(func(): _set_cursor_hover(false))
	button.pressed.connect(callback)
	return button

func _action_key(action: String, fallback: String) -> String:
	if not InputMap.has_action(action):
		return fallback
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if code != 0:
				return OS.get_keycode_string(code)
	return fallback

func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _connect_player_signal(player: Node, signal_name: String, callback: Callable) -> void:
	if not player.has_signal(signal_name):
		return
	var signal_ref := Signal(player, signal_name)
	if not signal_ref.is_connected(callback):
		signal_ref.connect(callback)

func _connect_manager_signal(manager: Node, signal_name: String, callback: Callable) -> void:
	if not manager.has_signal(signal_name):
		return
	var signal_ref := Signal(manager, signal_name)
	if not signal_ref.is_connected(callback):
		signal_ref.connect(callback)

func _refresh_device_controls() -> void:
	var device := get_node_or_null("/root/DeviceService")
	var settings := get_node_or_null("/root/SettingsService")
	var mobile: bool = device != null and (device.is_mobile() or device.has_touchscreen())
	if settings:
		mobile = mobile or settings.force_mobile_ui_on_desktop
	if _action_panel:
		_action_panel.visible = not mobile
	if mobile and not _mobile_controls:
		_mobile_controls = _build_mobile_buttons()
	elif not mobile and _mobile_controls:
		_mobile_controls.queue_free()
		_mobile_controls = null

func _build_mobile_buttons() -> Control:
	var grid := GridContainer.new()
	grid.name = "MobileActionButtons"
	grid.columns = 2
	grid.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	grid.offset_left = -166
	grid.offset_top = -180
	grid.offset_right = -16
	grid.offset_bottom = -24
	root.add_child(grid)
	grid.add_child(_mobile_button("Paint", _toggle_paint_mode))
	grid.add_child(_mobile_button("Pose", _toggle_pose_menu))
	grid.add_child(_mobile_button("Pipet", func(): if _player: _player.interact()))
	grid.add_child(_mobile_button("Spring", func(): if _player: _player.jump()))
	grid.add_child(_mobile_button("Hurk", func(): if _player: _player.set_mobile_crouching(not _player.mobile_crouching)))
	grid.add_child(_mobile_button("Pauze", _toggle_pause))
	return grid

func _mobile_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(72, 34)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)
	return button

func _toggle_pose_menu() -> void:
	if _pose_wheel.visible:
		_pose_wheel.close_wheel()
	else:
		_pose_wheel.open(_player)

func _toggle_paint_mode() -> void:
	if paint_ui:
		paint_ui.toggle()

func _toggle_rotation_lock() -> void:
	if _player:
		_player.rotation_locked = not _player.rotation_locked
		show_message("Rotatie %s" % ("vergrendeld" if _player.rotation_locked else "vrij"))

func _toggle_pause() -> void:
	if _player:
		var pause_menu := _player.get_parent().get_node_or_null("PauseMenu")
		if pause_menu and pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()

func _on_taunt_pressed() -> void:
	if _player:
		_player.taunt()

func _on_role_changed(is_hider: bool) -> void:
	role_label.text = "HIDER" if is_hider else "SEEKER"
	role_label.add_theme_color_override("font_color", Color(0.24, 0.98, 0.82) if is_hider else Color(1.0, 0.30, 0.28))
	energy_label.visible = not is_hider

func _on_color_sampled(_color: Color) -> void:
	show_message("Kleur gekopieerd - open Paint Mode om toe te passen")

func _on_phase_changed(name: String, seconds_left: int) -> void:
	phase_label.text = name.to_upper()
	_on_timer_changed(seconds_left)

func _on_timer_changed(seconds_left: int) -> void:
	var safe_seconds := maxi(seconds_left, 0)
	timer_label.text = "%02d:%02d" % [int(safe_seconds / 60), safe_seconds % 60]

func _on_round_state_changed(_new_state) -> void:
	if _round_manager and _round_manager.has_method("_state_name"):
		phase_label.text = _round_manager._state_name().to_upper()
	if _result_overlay and _round_manager and _round_manager.has_method("_state_name") and _round_manager._state_name() != "Round Results":
		_result_overlay.visible = false

func _on_camouflage_changed(percent: float, selected_part: String, pose_name: String) -> void:
	camo_label.text = "CAMOUFLAGE %d%%" % int(percent)
	camo_bar.value = percent
	part_label.text = "DEEL  %s" % selected_part
	pose_label.text = "POSE  %s" % pose_name

func _on_scan(found: bool, _target: Node, energy: float) -> void:
	energy_label.text = "ENERGIE %d" % int(energy)
	show_message("Hider gevonden" if found else "Scan mis - energie verbruikt")

func _on_scanner_fired(hit: bool) -> void:
	pulse.color = Color(0.30, 1.0, 0.55, 0.48) if hit else Color(1.0, 0.35, 0.20, 0.45)
	pulse.visible = true
	pulse_timer.start()

func _on_hider_count_changed(remaining: int, total: int) -> void:
	hiders_label.text = "HIDERS OVER  %d/%d" % [remaining, total]

func _on_role_counts_changed(hiders: int, seekers: int) -> void:
	counts_label.text = "HIDERS %d  |  SEEKERS %d" % [hiders, seekers]

func _on_taunt() -> void:
	show_message("Taunt geactiveerd")

func _on_scanner_cooldown(ready: bool, seconds_left: float) -> void:
	energy_label.text = "ENERGIE KLAAR" if ready else "COOLDOWN %.1fs" % seconds_left

func _on_paint_mode_toggled(open: bool) -> void:
	show_message("Paint Mode geopend" if open else "Paint Mode gesloten")

func _on_round_finished(winner: String) -> void:
	_result_label.text = "%s WINT" % winner
	_result_label.add_theme_color_override("font_color", Color(0.96, 0.22, 0.25) if winner == "SEEKER" else Color(0.26, 0.98, 0.80))
	_result_overlay.visible = true

func _set_cursor_hover(value: bool) -> void:
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor and cursor.has_method("set_hovered"):
		cursor.set_hovered(value)
