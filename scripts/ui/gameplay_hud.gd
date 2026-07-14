extends CanvasLayer

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")
const PaintModeScene := preload("res://scenes/ui/paint_mode_ui.tscn")
const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")

var root: Control
var role_label: Label
var phase_label: Label
var timer_label: Label
var camo_label: Label
var part_label: Label
var pose_label: Label
var energy_label: Label
var hiders_label: Label
var counts_label: Label
var username_label: Label
var paint_status_label: Label
var eyedropper_label: Label
var brush_label: Label
var shadow_label: Label
var message_label: Label
var mode_label: Label
var pulse: ColorRect
var message_timer: Timer
var pulse_timer: Timer
var paint_ui: Control
var _player: Node
var _round_manager: Node
var _mobile_controls: Control
var _pose_menu: PanelContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	var settings := get_node_or_null("/root/SettingsService")
	if settings:
		settings.settings_changed.connect(_refresh_device_controls)
	_refresh_device_controls()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pose_menu"):
		_toggle_pose_menu()
		get_viewport().set_input_as_handled()

func bind_player(player: Node) -> void:
	_player = player
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
	if round_manager.has_signal("phase_changed") and not round_manager.phase_changed.is_connected(_on_phase_changed):
		round_manager.phase_changed.connect(_on_phase_changed)
	if round_manager.has_signal("timer_changed") and not round_manager.timer_changed.is_connected(_on_timer_changed):
		round_manager.timer_changed.connect(_on_timer_changed)
	if round_manager.has_signal("round_message") and not round_manager.round_message.is_connected(show_message):
		round_manager.round_message.connect(show_message)
	if round_manager.has_signal("round_finished"):
		var callback := func(winner: String): show_message("%s wint de ronde" % winner)
		round_manager.round_finished.connect(callback)
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
	message_timer.start()

func _build() -> void:
	root = Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top_bar.offset_left = -270
	top_bar.offset_top = 18
	top_bar.offset_right = 270
	top_bar.offset_bottom = 82
	top_bar.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.03, 0.06, 0.11, 0.88), Color(0.18, 0.86, 0.82, 0.75)))
	root.add_child(top_bar)
	var top_box := VBoxContainer.new()
	top_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(top_box)
	phase_label = _label("WAITING", 20)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(phase_label)
	timer_label = _label("00:00", 28)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(timer_label)
	counts_label = _label("HIDERS 0   SEEKERS 0", 13)
	counts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(counts_label)

	var left := PanelContainer.new()
	left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left.offset_left = 18
	left.offset_top = 18
	left.offset_right = 300
	left.offset_bottom = 238
	left.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.03, 0.05, 0.10, 0.82), Color(0.54, 0.27, 0.92, 0.75)))
	root.add_child(left)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 4)
	left.add_child(left_box)
	var game_label := _label("MECCHA CHAMELEON", 14)
	game_label.add_theme_color_override("font_color", Color(0.25, 0.92, 0.82))
	left_box.add_child(game_label)
	username_label = _label("Speler: Camouflage-speler", 13)
	left_box.add_child(username_label)
	role_label = _label("ROL: HIDER", 19)
	left_box.add_child(role_label)
	camo_label = _label("CAMOUFLAGE: 0%", 18)
	left_box.add_child(camo_label)
	part_label = _label("DEEL: Torso", 15)
	left_box.add_child(part_label)
	pose_label = _label("POSE: Normaal staan", 15)
	left_box.add_child(pose_label)
	energy_label = _label("ENERGIE: 100", 15)
	left_box.add_child(energy_label)
	hiders_label = _label("HIDERS OVER: 0", 15)
	left_box.add_child(hiders_label)
	paint_status_label = _label("PAINT: gesloten", 12)
	left_box.add_child(paint_status_label)
	eyedropper_label = _label("PIPET: klaar", 12)
	left_box.add_child(eyedropper_label)
	brush_label = _label("BRUSH: 25%", 12)
	left_box.add_child(brush_label)
	shadow_label = _label("SCHADUW: aan", 12)
	left_box.add_child(shadow_label)

	message_label = _label("", 22)
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.offset_left = -360
	message_label.offset_top = 102
	message_label.offset_right = 360
	message_label.offset_bottom = 138
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(message_label)

	pulse = ColorRect.new()
	pulse.name = "ScanPulse"
	pulse.set_anchors_preset(Control.PRESET_CENTER)
	pulse.offset_left = -22
	pulse.offset_top = -22
	pulse.offset_right = 22
	pulse.offset_bottom = 22
	pulse.color = Color(0.2, 1.0, 0.75, 0.40)
	pulse.visible = false
	root.add_child(pulse)
	_create_crosshair()

	var shortcuts := PanelContainer.new()
	shortcuts.name = "Shortcuts"
	shortcuts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	shortcuts.offset_left = -280
	shortcuts.offset_top = 18
	shortcuts.offset_right = -18
	shortcuts.offset_bottom = 178
	shortcuts.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.03, 0.05, 0.10, 0.76), Color(0.18, 0.86, 0.82, 0.55)))
	root.add_child(shortcuts)
	var shortcuts_box := VBoxContainer.new()
	shortcuts_box.add_theme_constant_override("separation", 2)
	shortcuts.add_child(shortcuts_box)
	var shortcut_title := _label("BESTURING", 15)
	shortcuts_box.add_child(shortcut_title)
	for action_name in ["move_forward", "sprint", "crouch", "pose_next", "paint_mode", "pose_menu", "taunt", "pause", "toggle_rotation_lock", "toggle_name_labels", "toggle_xray"]:
		shortcuts_box.add_child(_label("%s  %s" % [_action_label(action_name), _action_key(action_name)], 12))

	mode_label = _label("INFECTION  •  Verstop, match je omgeving en blijf stil.", 14)
	mode_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mode_label.offset_left = 18
	mode_label.offset_top = -54
	mode_label.offset_right = -18
	mode_label.offset_bottom = -18
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(mode_label)

	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 2.6
	message_timer.timeout.connect(func(): message_label.text = "")
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

func _create_crosshair() -> void:
	var crosshair := Control.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -12
	crosshair.offset_top = -12
	crosshair.offset_right = 12
	crosshair.offset_bottom = 12
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	var horizontal := ColorRect.new()
	horizontal.position = Vector2(2, 11)
	horizontal.size = Vector2(20, 2)
	horizontal.color = Color(0.95, 1.0, 0.96, 0.92)
	crosshair.add_child(horizontal)
	var vertical := ColorRect.new()
	vertical.position = Vector2(11, 2)
	vertical.size = Vector2(2, 20)
	vertical.color = Color(0.95, 1.0, 0.96, 0.92)
	crosshair.add_child(vertical)

func _refresh_device_controls() -> void:
	if not root:
		return
	var device := get_node_or_null("/root/DeviceService")
	var settings := get_node_or_null("/root/SettingsService")
	var mobile: bool = device != null and (device.is_mobile() or device.has_touchscreen())
	if settings:
		mobile = mobile or settings.force_mobile_ui_on_desktop
	if mobile and not _mobile_controls:
		_mobile_controls = _build_mobile_buttons()
	elif not mobile and _mobile_controls:
		_mobile_controls.queue_free()
		_mobile_controls = null

func _build_mobile_buttons() -> Control:
	var box := VBoxContainer.new()
	box.name = "MobileActionButtons"
	box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	box.offset_left = -166
	box.offset_top = -230
	box.offset_right = -18
	box.offset_bottom = -74
	box.add_theme_constant_override("separation", 8)
	root.add_child(box)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	grid.add_child(_mobile_button("Paint", func(): if paint_ui: paint_ui.toggle()))
	grid.add_child(_mobile_button("Pose", _toggle_pose_menu))
	var eyedropper := _mobile_button("Pipet", func(): pass)
	eyedropper.button_down.connect(func(): if _player and _player.has_method("set_mobile_eyedropper"): _player.set_mobile_eyedropper(true))
	eyedropper.button_up.connect(func(): if _player and _player.has_method("set_mobile_eyedropper"): _player.set_mobile_eyedropper(false))
	grid.add_child(eyedropper)
	grid.add_child(_mobile_button("Taunt", func(): if _player and _player.has_method("taunt"): _player.taunt()))
	grid.add_child(_mobile_button("Spring", func(): if _player and _player.has_method("jump"): _player.jump()))
	grid.add_child(_mobile_button("Hurk", func(): if _player and _player.has_method("set_mobile_crouching"): _player.set_mobile_crouching(not _player.mobile_crouching)))
	grid.add_child(_mobile_button("Actie", func(): if _player and _player.has_method("interact"): _player.interact()))
	grid.add_child(_mobile_button("Scan", func(): if _player and _player.has_method("scan"): _player.scan()))
	grid.add_child(_mobile_button("Pauze", _toggle_pause))
	return box

func _mobile_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(142, 42)
	button.add_theme_stylebox_override("normal", UI_STYLE.button(Color(0.05, 0.12, 0.18, 0.90), Color(0.18, 0.86, 0.82, 0.95)))
	button.pressed.connect(callback)
	return button

func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.92, 0.96, 0.98))
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
		"toggle_rotation_lock": return "Rotatie"
		"toggle_name_labels": return "Naamlabels"
		"toggle_xray": return "X-ray DEBUG"
		"action": return "Actie"
		_: return action

func _action_key(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "-"
	return events[0].as_text()

func _on_role_changed(is_hider: bool) -> void:
	role_label.text = "ROL: HIDER" if is_hider else "ROL: SEEKER"
	mode_label.text = "INFECTION  •  Verstop, match je omgeving en blijf stil." if is_hider else "INFECTION  •  Scan verdachte plekken en besmet alle hiders."

func _on_color_sampled(_color: Color) -> void:
	show_message("Oppervlaktekleur gekopieerd")
	if eyedropper_label:
		eyedropper_label.text = "PIPET: kleur gevonden"

func _on_eyedropper_previewed(_color: Color, valid: bool) -> void:
	if eyedropper_label:
		eyedropper_label.text = "PIPET: %s" % ("preview" if valid else "klaar")

func _on_phase_changed(name: String, seconds_left: int) -> void:
	phase_label.text = name.to_upper()
	_on_timer_changed(seconds_left)

func _on_timer_changed(seconds_left: int) -> void:
	var minutes := int(max(seconds_left, 0) / 60)
	var seconds: int = max(seconds_left, 0) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_round_state_changed(new_state) -> void:
	if _round_manager and _round_manager.has_method("_state_name"):
		phase_label.text = _round_manager._state_name().to_upper()

func _on_camouflage_changed(percent: float, selected_part: String, pose_name: String) -> void:
	camo_label.text = "CAMOUFLAGE: %d%%" % int(percent)
	part_label.text = "DEEL: %s" % selected_part
	pose_label.text = "POSE: %s" % pose_name

func _on_scan(found: bool, _target: Node, energy: float) -> void:
	energy_label.text = "ENERGIE: %d" % int(energy)
	show_message("Hider gevonden" if found else "Scan mis - energie verbruikt")

func _on_scanner_fired(hit: bool) -> void:
	pulse.color = Color(0.30, 1.0, 0.55, 0.48) if hit else Color(1.0, 0.35, 0.20, 0.45)
	pulse.visible = true
	pulse_timer.start()

func _on_hider_count_changed(remaining: int, total: int) -> void:
	hiders_label.text = "HIDERS OVER: %d/%d" % [remaining, total]

func _on_role_counts_changed(hiders: int, seekers: int) -> void:
	counts_label.text = "HIDERS %d   SEEKERS %d" % [hiders, seekers]

func _on_taunt() -> void:
	show_message("Taunt geactiveerd")

func _on_scanner_cooldown(ready: bool, seconds_left: float) -> void:
	if ready:
		energy_label.text = "ENERGIE: klaar"
	else:
		energy_label.text = "ENERGIE: cooldown %.1fs" % seconds_left

func _on_paint_mode_toggled(open: bool) -> void:
	paint_status_label.text = "PAINT: open" if open else "PAINT: gesloten"

func _toggle_pause() -> void:
	if _player:
		var pause_menu := _player.get_parent().get_node_or_null("PauseMenu")
		if pause_menu and pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()

func _toggle_pose_menu() -> void:
	if _pose_menu and is_instance_valid(_pose_menu):
		_pose_menu.visible = not _pose_menu.visible
		return
	_pose_menu = PanelContainer.new()
	_pose_menu.name = "PoseMenu"
	_pose_menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pose_menu.offset_left = -360
	_pose_menu.offset_top = -148
	_pose_menu.offset_right = 360
	_pose_menu.offset_bottom = -62
	_pose_menu.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.03, 0.05, 0.10, 0.95), Color(0.55, 0.25, 0.92, 0.90)))
	root.add_child(_pose_menu)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	_pose_menu.add_child(row)
	for i in range(PoseManagerScript.POSE_NAMES.size()):
		var pose_index := i
		var button := _mobile_button(PoseManagerScript.POSE_NAMES[i], func():
			if _player and _player.pose_manager:
				_player.pose_manager.set_pose(pose_index)
			_pose_menu.visible = false)
		button.custom_minimum_size = Vector2(66, 54)
		row.add_child(button)
