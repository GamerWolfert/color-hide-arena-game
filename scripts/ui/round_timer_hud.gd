extends Control

var phase_label: Label
var timer_label: Label
var counts_label: Label
var _phase := "WACHTEN"
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
	phase_label.offset_left = -190
	phase_label.offset_top = 56
	phase_label.offset_right = 190
	phase_label.offset_bottom = 76
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.text = _phase
	phase_label.add_theme_font_size_override("font_size", 12)
	phase_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	add_child(phase_label)
	timer_label = Label.new()
	timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timer_label.offset_left = -90
	timer_label.offset_top = 30
	timer_label.offset_right = 90
	timer_label.offset_bottom = 61
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 27)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	add_child(timer_label)
	counts_label = Label.new()
	counts_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	counts_label.offset_left = -150
	counts_label.offset_top = 76
	counts_label.offset_right = 150
	counts_label.offset_bottom = 94
	counts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counts_label.text = "HIDERS 0  •  SEEKERS 0"
	counts_label.add_theme_font_size_override("font_size", 11)
	counts_label.add_theme_color_override("font_color", Color(0.76, 0.86, 0.96))
	add_child(counts_label)

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 22.0)
	draw_style_box(_panel_style(Color(0.02, 0.035, 0.075, 0.68), Color(0.16, 0.72, 0.76, 0.52)), Rect2(center.x - 190.0, 8.0, 380.0, 90.0))
	for index in range(3):
		_draw_humanoid(center + Vector2(-124.0 + index * 28.0, 10.0), Color(0.92, 0.94, 0.90))
	_draw_hourglass(center + Vector2(0, 11.0))
	_draw_humanoid(center + Vector2(124.0, 10.0), Color(0.92, 0.18, 0.24))

func _draw_humanoid(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(0, -5), 4.0, color)
	draw_circle(center + Vector2(0, 4), 5.0, color)
	draw_line(center + Vector2(-3, 8), center + Vector2(-5, 16), color, 2.5, true)
	draw_line(center + Vector2(3, 8), center + Vector2(5, 16), color, 2.5, true)
	draw_line(center + Vector2(-5, 2), center + Vector2(-8, 8), color, 2.0, true)
	draw_line(center + Vector2(5, 2), center + Vector2(8, 8), color, 2.0, true)

func _draw_hourglass(center: Vector2) -> void:
	var turquoise := Color(0.20, 0.94, 0.78)
	draw_line(center + Vector2(-8, -10), center + Vector2(8, -10), turquoise, 2.0)
	draw_line(center + Vector2(-8, 12), center + Vector2(8, 12), turquoise, 2.0)
	draw_line(center + Vector2(-7, -9), center + Vector2(7, 11), turquoise, 1.5)
	draw_line(center + Vector2(7, -9), center + Vector2(-7, 11), turquoise, 1.5)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-4, 4), center + Vector2(4, 4), center + Vector2(0, 10)]), Color(0.20, 0.78, 0.58, 0.9))

func _on_phase_changed(name: String, seconds_left: int) -> void:
	_phase = name.to_upper()
	_seconds = seconds_left
	if _phase == "SEARCHING":
		_phase = "ZOEKFASE"
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
		timer_label.text = "%02d" % safe_seconds if safe_seconds < 60 else "%02d:%02d" % [int(safe_seconds / 60), safe_seconds % 60]
	if counts_label:
		counts_label.text = "HIDERS %d  •  SEEKERS %d" % [_hiders, _seekers]
	queue_redraw()

func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style
