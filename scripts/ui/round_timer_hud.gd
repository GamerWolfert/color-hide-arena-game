extends Control

var phase_label: Label
var timer_label: Label
var counts_label: Label
var _phase := "WACHTEN OP SPELERS"
var _seconds := 0
var _hiders := 0
var _seekers := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_labels()
	queue_redraw()

func bind_round_manager(round_manager: Node) -> void:
	if round_manager.has_signal("phase_changed") and not round_manager.phase_changed.is_connected(_on_phase_changed):
		round_manager.phase_changed.connect(_on_phase_changed)
	if round_manager.has_signal("timer_changed") and not round_manager.timer_changed.is_connected(_on_timer_changed):
		round_manager.timer_changed.connect(_on_timer_changed)
	if round_manager.has_signal("role_counts_changed") and not round_manager.role_counts_changed.is_connected(_on_role_counts_changed):
		round_manager.role_counts_changed.connect(_on_role_counts_changed)
	if round_manager.has_method("_phase_name"):
		_on_phase_changed(round_manager._phase_name(), round_manager.seconds_left)

func _build_labels() -> void:
	phase_label = Label.new()
	phase_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	phase_label.offset_left = -130
	phase_label.offset_top = 54
	phase_label.offset_right = 130
	phase_label.offset_bottom = 70
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.text = _phase
	phase_label.add_theme_font_size_override("font_size", 10)
	phase_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	add_child(phase_label)
	timer_label = Label.new()
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.offset_left = -90
	timer_label.offset_top = 25
	timer_label.offset_right = 90
	timer_label.offset_bottom = 51
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 23)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	add_child(timer_label)
	counts_label = Label.new()
	counts_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	counts_label.offset_left = -150
	counts_label.offset_top = 71
	counts_label.offset_right = 150
	counts_label.offset_bottom = 86
	counts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counts_label.text = "HIDERS 0  |  SEEKERS 0"
	counts_label.add_theme_font_size_override("font_size", 9)
	counts_label.add_theme_color_override("font_color", Color(0.76, 0.86, 0.96))
	add_child(counts_label)

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 16.0)
	draw_style_box(_panel_style(), Rect2(center.x - 112.0, 4.0, 224.0, 86.0))
	_draw_team_icons(center, _hiders, Color(0.94, 0.95, 0.91), -1.0)
	_draw_hourglass(center + Vector2(0, 7.0))
	_draw_team_icons(center, _seekers, Color(0.94, 0.16, 0.22), 1.0)

func _draw_team_icons(center: Vector2, count: int, color: Color, side: float) -> void:
	var visible_count := mini(count, 8)
	var gap := 18.0
	var start_x := center.x + side * (38.0 + (visible_count - 1) * gap * 0.5)
	if side < 0.0:
		start_x -= (visible_count - 1) * gap
	for index in range(visible_count):
		_draw_humanoid(Vector2(start_x + index * gap, center.y + 7.0), color)
	if count > visible_count:
		draw_string(ThemeDB.fallback_font, Vector2(start_x + side * (visible_count * gap + 1.0), center.y + 11.0), "x%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, color)

func _draw_humanoid(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(0, -4), 3.4, color)
	draw_circle(center + Vector2(0, 3), 4.4, color)
	draw_line(center + Vector2(-2.5, 6), center + Vector2(-4, 13), color, 2.2, true)
	draw_line(center + Vector2(2.5, 6), center + Vector2(4, 13), color, 2.2, true)
	draw_line(center + Vector2(-4, 1), center + Vector2(-7, 7), color, 1.8, true)
	draw_line(center + Vector2(4, 1), center + Vector2(7, 7), color, 1.8, true)

func _draw_hourglass(center: Vector2) -> void:
	var turquoise := Color(0.20, 0.94, 0.78)
	draw_line(center + Vector2(-7, -8), center + Vector2(7, -8), turquoise, 1.8)
	draw_line(center + Vector2(-7, 10), center + Vector2(7, 10), turquoise, 1.8)
	draw_line(center + Vector2(-6, -7), center + Vector2(6, 9), turquoise, 1.4)
	draw_line(center + Vector2(6, -7), center + Vector2(-6, 9), turquoise, 1.4)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-3, 3), center + Vector2(3, 3), center + Vector2(0, 8)]), Color(0.20, 0.78, 0.58, 0.9))

func _on_phase_changed(name: String, seconds_left: int) -> void:
	_phase = name.to_upper()
	_seconds = seconds_left
	match _phase:
		"HIDING": _phase = "ZOEKFASE START OVER"
		"SEARCHING": _phase = "ZOEKFASE"
		"WAITING": _phase = "WACHTEN OP SPELERS"
		"ROLE ASSIGNMENT": _phase = "ROLLEN WORDEN VERDEELD"
	_update_labels()

func _on_timer_changed(seconds_left: int) -> void:
	_seconds = seconds_left
	_update_labels()

func _on_role_counts_changed(hiders: int, seekers: int) -> void:
	_hiders = hiders
	_seekers = seekers
	_update_labels()

func _update_labels() -> void:
	if phase_label:
		phase_label.text = _phase
	if timer_label:
		var safe_seconds := maxi(_seconds, 0)
		timer_label.text = "%02d:%02d" % [int(safe_seconds / 60), safe_seconds % 60]
	if counts_label:
		counts_label.text = "HIDERS %d  |  SEEKERS %d" % [_hiders, _seekers]
	queue_redraw()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.035, 0.075, 0.58)
	style.border_color = Color(0.16, 0.72, 0.76, 0.44)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	return style
