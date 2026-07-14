extends CanvasLayer

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")
const PaintModeScene := preload("res://scenes/ui/paint_mode_ui.tscn")
const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")
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
var paint_status_label: Label
var eyedropper_label: Label
var message_label: Label
var mode_label: Label
var pulse: ColorRect
var message_timer: Timer
var pulse_timer: Timer
var paint_ui: Control
var _player: Node
var _round_manager: Node
var _mobile_controls: Control
var _action_panel: PanelContainer
var _pose_menu: PanelContainer
var _pose_wheel: Control
var _round_timer_ui: Control

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
	elif _pose_menu and _pose_menu.visible and event.is_action_pressed("ui_cancel"):
		_close_pose_menu()
		get_viewport().set_input_as_handled()

func bind_player(player: Node) -> void:
	_player = player
	var session := get_node_or_null("/root/SessionManager")
	if session and not session.display_name.is_empty():
		username_label.text = str(session.display_name)
	if player.has_signal("role_changed") and not player.role_changed.is_connected(_on_role_changed):
		player.role_changed.connect(_on_role_changed)
	if player.has_signal("color_sampled") and not player.color_sampled.is_connected(_on_color_sampled):
		player.color_sampled.connect(_on_color_sampled)
	if player.has_signal("eyedropper_previewed") and not player.eyedropper_previewed.is_connected(_on_eyedropper_previewed):
		player.eyedropper_previewed.connect(_on_eyedropper_previewed)
	if player.has_signal("seeker_scanned") and not player.seeker_scanned.is_connected(_on_scan):
		player.seeker_scanned.connect(_on_scan)
	if player.has_signal("camouflage_changed") and not player.camouflage_changed.is_connected(_on_camouflage_changed):
		player.camouflage_changed.connect(_on_camouflage_changed)
	if player.has_signal("scanner_fired") and not player.scanner_fired.is_connected(_on_scanner_fired):
		player.scanner_fired.connect(_on_scanner_fired)
	if player.has_signal("taunt_requested") and not player.taunt_requested.is_connected(_on_taunt):
		player.taunt_requested.connect(_on_taunt)
	if player.has_signal("scanner_cooldown_changed") and not player.scanner_cooldown_changed.is_connected(_on_scanner_cooldown):
		player.scanner_cooldown_changed.connect(_on_scanner_cooldown)
	if paint_ui:
		paint_ui.bind_player(player)
	if player.get("is_hider") != null:
		_on_role_changed(player.is_hider)

func bind_round_manager(round_manager: Node) -> void:
	_round_manager = round_manager
	if _round_timer_ui and _round_timer_ui.has_method("bind_round_manager"):
		_round_timer_ui.bind_round_manager(round_manager)
	if round_manager.has_signal("phase_changed") and not round_manager.phase_changed.is_connected(_on_phase_changed):
		round_manager.phase_changed.connect(_on_phase_changed)
	if round_manager.has_signal("timer_changed") and not round_manager.timer_changed.is_connected(_on_timer_changed):
		round_manager.timer_changed.connect(_on_timer_changed)
	if round_manager.has_signal("round_message") and not round_manager.round_message.is_connected(show_message):
		round_manager.round_message.connect(show_message)
	if round_manager.has_signal("round_finished"):
		round_manager.round_finished.connect(func(winner: String): show_message("%s wint de ronde" % winner))
	if round_manager.has_signal("hider_count_changed") and not round_manager.hider_count_changed.is_connected(_on_hider_count_changed):
		round_manager.hider_count_changed.connect(_on_hider_count_changed)
	if round_manager.has_signal("role_counts_changed") and not round_manager.role_counts_changed.is_connected(_on_role_counts_changed):
		round_manager.role_counts_changed.connect(_on_role_counts_changed)
	if round_manager.has_signal("state_changed") and not round_manager.state_changed.is_connected(_on_round_state_changed):
		round_manager.state_changed.connect(_on_round_state_changed)

func show_message(text: String) -> void:
	if not message_label:
		return
	message_label.text = text
	message_label.visible = not text.is_empty()
	message_timer.start()

func _build() -> void:
	root = Control.new()
	root.name = "GameplayOverlay"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.z_index = 20
	add_child(root)

	var player_card := _panel(Control.PRESET_TOP_LEFT, Vector4(18, 18, 274, 184), Color(0.025, 0.045, 0.085, 0.84), Color(0.10, 0.82, 0.78, 0.72))
	root.add_child(player_card)
	var player_box := _box(player_card, 7)
	var game_label := _label("MECCHA CHAMELEON", 13)
	game_label.add_theme_color_override("font_color", Color(0.28, 0.97, 0.86))
	player_box.add_child(game_label)
	username_label = _label("Camouflage-speler", 16)
	player_box.add_child(username_label)
	role_label = _label("HIDER", 19)
	player_box.add_child(role_label)
	camo_label = _label("CAMOUFLAGE 0%", 14)
	player_box.add_child(camo_label)
	camo_bar = ProgressBar.new()
	camo_bar.max_value = 100.0
	camo_bar.value = 0.0
	camo_bar.show_percentage = false
	camo_bar.custom_minimum_size = Vector2(0, 7)
	camo_bar.add_theme_stylebox_override("background", _bar_style(Color(0.04, 0.08, 0.13, 0.95), Color(0.02, 0.04, 0.07, 1.0)))
	camo_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.14, 0.88, 0.74, 1.0), Color(0.14, 0.88, 0.74, 1.0)))
	player_box.add_child(camo_bar)
	part_label = _label("DEEL  Torso", 12)
	pose_label = _label("POSE  Normaal staan", 12)
	player_box.add_child(part_label)
	player_box.add_child(pose_label)

	_round_timer_ui = RoundTimerScene.instantiate()
	root.add_child(_round_timer_ui)
	phase_label = _round_timer_ui.phase_label
	timer_label = _round_timer_ui.timer_label
	counts_label = _round_timer_ui.counts_label

	var intel_card := _panel(Control.PRESET_TOP_RIGHT, Vector4(-250, 18, -18, 142), Color(0.025, 0.045, 0.085, 0.84), Color(0.55, 0.27, 0.95, 0.72))
	root.add_child(intel_card)
	var intel_box := _box(intel_card, 7)
	var intel_title := _label("RONDESTATUS", 12)
	intel_title.add_theme_color_override("font_color", Color(0.75, 0.48, 1.0))
	intel_box.add_child(intel_title)
	hiders_label = _label("HIDERS OVER  0/0", 16)
	intel_box.add_child(hiders_label)
	energy_label = _label("ENERGIE  100", 14)
	intel_box.add_child(energy_label)
	paint_status_label = _label("PAINT  gesloten", 12)
	eyedropper_label = _label("PIPET  klaar", 12)
	intel_box.add_child(paint_status_label)
	intel_box.add_child(eyedropper_label)
	_build_action_panel()

	message_label = _label("", 18)
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.offset_left = -300
	message_label.offset_top = 100
	message_label.offset_right = 300
	message_label.offset_bottom = 132
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.visible = false
	root.add_child(message_label)
	_create_crosshair()

	var bottom_left := _panel(Control.PRESET_BOTTOM_LEFT, Vector4(18, -76, 412, -18), Color(0.025, 0.045, 0.085, 0.78), Color(0.10, 0.82, 0.78, 0.52))
	root.add_child(bottom_left)
	var hints := _label("WASD bewegen   SHIFT sprint   SPACE springen   C hurken", 11)
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_left.add_child(hints)

	var bottom_right := _panel(Control.PRESET_BOTTOM_RIGHT, Vector4(-420, -76, -18, -18), Color(0.025, 0.045, 0.085, 0.78), Color(0.55, 0.27, 0.95, 0.52))
	root.add_child(bottom_right)
	var actions := _label("E pipet   F paint   P poses   L rotatie   ESC pauze", 11)
	actions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_right.add_child(actions)

	mode_label = _label("INFECTION  •  Kopieer kleur, kies een pose en blijf stil.", 13)
	mode_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mode_label.offset_left = 430
	mode_label.offset_top = -116
	mode_label.offset_right = -430
	mode_label.offset_bottom = -88
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(mode_label)

	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 2.6
	message_timer.timeout.connect(func(): message_label.visible = false)
	add_child(message_timer)
	pulse_timer = Timer.new()
	pulse_timer.one_shot = true
	pulse_timer.wait_time = 0.16
	pulse_timer.timeout.connect(func(): pulse.visible = false)
	add_child(pulse_timer)

	paint_ui = PaintModeScene.instantiate()
	paint_ui.name = "PaintModeUI"
	root.add_child(paint_ui)
	paint_ui.paint_mode_toggled.connect(_on_paint_mode_toggled)

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

func _box(parent: Control, separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box

func _bar_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _create_crosshair() -> void:
	var crosshair := Control.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -14
	crosshair.offset_top = -14
	crosshair.offset_right = 14
	crosshair.offset_bottom = 14
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	for rect in [Rect2(13, 0, 2, 8), Rect2(13, 20, 2, 8), Rect2(0, 13, 8, 2), Rect2(20, 13, 8, 2)]:
		var mark := ColorRect.new()
		mark.position = rect.position
		mark.size = rect.size
		mark.color = Color(0.94, 1.0, 0.96, 0.94)
		crosshair.add_child(mark)
	var dot := ColorRect.new()
	dot.position = Vector2(13, 13)
	dot.size = Vector2(2, 2)
	dot.color = Color(0.25, 0.96, 0.82, 1.0)
	crosshair.add_child(dot)
	pulse = ColorRect.new()
	pulse.position = Vector2(4, 4)
	pulse.size = Vector2(20, 20)
	pulse.color = Color(0.2, 1.0, 0.75, 0.35)
	pulse.visible = false
	crosshair.add_child(pulse)

func _refresh_device_controls() -> void:
	if not root:
		return
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
	var box := VBoxContainer.new()
	box.name = "MobileActionButtons"
	box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	box.offset_left = -170
	box.offset_top = -238
	box.offset_right = -18
	box.offset_bottom = -84
	box.add_theme_constant_override("separation", 6)
	root.add_child(box)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	box.add_child(grid)
	grid.add_child(_mobile_button("Paint", func(): if paint_ui: paint_ui.toggle()))
	grid.add_child(_mobile_button("Pose", _toggle_pose_menu))
	grid.add_child(_mobile_button("Pipet", func(): if _player: _player.interact()))
	grid.add_child(_mobile_button("Spring", func(): if _player: _player.jump()))
	grid.add_child(_mobile_button("Hurk", func(): if _player: _player.set_mobile_crouching(not _player.mobile_crouching)))
	grid.add_child(_mobile_button("Actie", func(): if _player: _player.interact()))
	grid.add_child(_mobile_button("Scan", func(): if _player: _player.scan()))
	grid.add_child(_mobile_button("Pauze", _toggle_pause))
	return box

func _build_action_panel() -> void:
	_action_panel = _panel(Control.PRESET_TOP_RIGHT, Vector4(-250, 154, -18, 398), Color(0.025, 0.045, 0.085, 0.84), Color(0.55, 0.27, 0.95, 0.72))
	_action_panel.name = "ActionPanel"
	root.add_child(_action_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	_action_panel.add_child(content)
	var title := _label("ACTIES", 12)
	title.add_theme_color_override("font_color", Color(0.75, 0.48, 1.0))
	content.add_child(title)
	content.add_child(_action_button("Taunt", "taunt", _on_taunt_pressed, Color(0.55, 0.27, 0.95, 0.9)))
	content.add_child(_action_button("Posewiel", "pose_menu", _toggle_pose_menu, Color(0.10, 0.82, 0.78, 0.9)))
	content.add_child(_action_button("Paint Mode", "paint_mode", _toggle_paint_mode, Color(0.10, 0.82, 0.78, 0.9)))
	content.add_child(_action_button("Rotatie vergrendelen", "toggle_rotation_lock", _toggle_rotation_lock, Color(0.55, 0.27, 0.95, 0.9)))
	content.add_child(_action_button("Pauzeren", "pause", _toggle_pause, Color(0.95, 0.72, 0.22, 0.9)))

func _action_button(label_text: String, action: String, callback: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.text = "[%s]  %s" % [_action_key(action, "-") , label_text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 32)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_stylebox_override("normal", UI_STYLE.button(Color(0.04, 0.09, 0.15, 0.92), accent))
	button.add_theme_stylebox_override("hover", UI_STYLE.button(Color(0.10, 0.06, 0.19, 0.98), Color(0.88, 0.42, 1.0, 1.0)))
	button.add_theme_stylebox_override("pressed", UI_STYLE.button(Color(0.08, 0.20, 0.20, 1.0), Color(0.20, 1.0, 0.82, 1.0)))
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
		if event is InputEventMouseButton:
			return "MUIS"
	return fallback

func _on_taunt_pressed() -> void:
	if _player:
		_player.taunt()

func _toggle_paint_mode() -> void:
	if paint_ui:
		paint_ui.toggle()

func _toggle_rotation_lock() -> void:
	if _player:
		_player.rotation_locked = not _player.rotation_locked
		show_message("Rotatie %s" % ("vergrendeld" if _player.rotation_locked else "vrij"))

func _mobile_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(74, 36)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", UI_STYLE.button(Color(0.05, 0.12, 0.18, 0.92), Color(0.18, 0.86, 0.82, 0.95)))
	button.pressed.connect(callback)
	return button

func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.98))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _action_label(action: String) -> String:
	match action:
		"move_forward": return "Beweeg"
		"sprint": return "Sprint"
		"crouch": return "Hurk"
		"pose_next": return "Pose"
		"pose_menu": return "Pose-menu"
		"paint_mode": return "Paint"
		"taunt": return "Taunt"
		"pause": return "Pauze"
		_: return action

func _on_role_changed(is_hider: bool) -> void:
	role_label.text = "HIDER" if is_hider else "SEEKER"
	role_label.add_theme_color_override("font_color", Color(0.28, 0.97, 0.86) if is_hider else Color(1.0, 0.35, 0.32))
	mode_label.text = "INFECTION  •  Kopieer kleur, kies een pose en blijf stil." if is_hider else "INFECTION  •  Scan verdachte plekken en vind alle hiders."

func _on_color_sampled(_color: Color) -> void:
	show_message("Oppervlaktekleur gekopieerd")
	eyedropper_label.text = "PIPET  kleur gevonden"

func _on_eyedropper_previewed(_color: Color, valid: bool) -> void:
	eyedropper_label.text = "PIPET  %s" % ("preview" if valid else "klaar")

func _on_phase_changed(name: String, seconds_left: int) -> void:
	phase_label.text = name.to_upper()
	_on_timer_changed(seconds_left)

func _on_timer_changed(seconds_left: int) -> void:
	var safe_seconds := maxi(seconds_left, 0)
	timer_label.text = "%02d:%02d" % [int(safe_seconds / 60), safe_seconds % 60]

func _on_round_state_changed(_new_state) -> void:
	if _round_manager and _round_manager.has_method("_state_name"):
		phase_label.text = _round_manager._state_name().to_upper()

func _on_camouflage_changed(percent: float, selected_part: String, pose_name: String) -> void:
	camo_label.text = "CAMOUFLAGE %d%%" % int(percent)
	camo_bar.value = percent
	part_label.text = "DEEL  %s" % selected_part
	pose_label.text = "POSE  %s" % pose_name

func _on_scan(found: bool, _target: Node, energy: float) -> void:
	energy_label.text = "ENERGIE  %d" % int(energy)
	show_message("Hider gevonden" if found else "Scan mis - energie verbruikt")

func _on_scanner_fired(hit: bool) -> void:
	pulse.color = Color(0.30, 1.0, 0.55, 0.48) if hit else Color(1.0, 0.35, 0.20, 0.45)
	pulse.visible = true
	pulse_timer.start()

func _on_hider_count_changed(remaining: int, total: int) -> void:
	hiders_label.text = "HIDERS OVER  %d/%d" % [remaining, total]

func _on_role_counts_changed(hiders: int, seekers: int) -> void:
	counts_label.text = "HIDERS %d  •  SEEKERS %d" % [hiders, seekers]

func _on_taunt() -> void:
	show_message("Taunt geactiveerd")

func _on_scanner_cooldown(ready: bool, seconds_left: float) -> void:
	if ready:
		energy_label.text = "ENERGIE  klaar"
	else:
		energy_label.text = "ENERGIE  cooldown %.1fs" % seconds_left

func _on_paint_mode_toggled(open: bool) -> void:
	paint_status_label.text = "PAINT  open" if open else "PAINT  gesloten"
	_set_cursor_mode(2 if open else 0)

func _toggle_pause() -> void:
	if _player:
		var pause_menu := _player.get_parent().get_node_or_null("PauseMenu")
		if pause_menu and pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()

func _toggle_pose_menu() -> void:
	if _pose_wheel == null:
		_pose_wheel = PoseWheelScene.instantiate()
		_pose_wheel.name = "PoseWheel"
		root.add_child(_pose_wheel)
	if _pose_wheel.visible:
		_pose_wheel.close_wheel()
	else:
		_pose_wheel.open(_player)
	return
	# Legacy fallback remains below for old saved scenes.
	if _pose_menu and is_instance_valid(_pose_menu):
		if _pose_menu.visible:
			_close_pose_menu()
		else:
			_pose_menu.visible = true
			var input_service := get_node_or_null("/root/InputService")
			if input_service:
				input_service.set_touch_input_blocked(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	_pose_menu = PanelContainer.new()
	_pose_menu.name = "PoseMenu"
	_pose_menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pose_menu.offset_left = -280
	_pose_menu.offset_top = -184
	_pose_menu.offset_right = 280
	_pose_menu.offset_bottom = -70
	_pose_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_pose_menu.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.025, 0.045, 0.085, 0.98), Color(0.55, 0.25, 0.92, 0.94)))
	root.add_child(_pose_menu)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	_pose_menu.add_child(content)
	var title := _label("POSEMENU  •  kies een houding", 13)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for i in range(PoseManagerScript.POSE_NAMES.size()):
		var pose_index := i
		var button := Button.new()
		button.text = PoseManagerScript.POSE_NAMES[i]
		button.custom_minimum_size = Vector2(164, 34)
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_stylebox_override("normal", UI_STYLE.button(Color(0.04, 0.10, 0.16, 0.96), Color(0.12, 0.80, 0.78, 0.82)))
		button.add_theme_stylebox_override("hover", UI_STYLE.button(Color(0.12, 0.06, 0.20, 1.0), Color(0.72, 0.36, 1.0, 1.0)))
		button.pressed.connect(func():
			if _player and _player.pose_manager:
				_player.pose_manager.set_pose(pose_index)
			_close_pose_menu()
		)
		grid.add_child(button)
	var menu_input_service := get_node_or_null("/root/InputService")
	if menu_input_service:
		menu_input_service.set_touch_input_blocked(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _close_pose_menu() -> void:
	if _pose_menu and is_instance_valid(_pose_menu):
		_pose_menu.visible = false
	var input_service := get_node_or_null("/root/InputService")
	if input_service:
		input_service.set_touch_input_blocked(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _set_cursor_mode(mode: int) -> void:
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor:
		cursor.set_mode(mode)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if mode != 0 else Input.MOUSE_MODE_CAPTURED)
