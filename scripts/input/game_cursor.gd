extends Control

enum CursorMode { UI, PAINT, EYEDROPPER }

var cursor_mode := CursorMode.UI
var pressed := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	queue_redraw()

func set_cursor_mode(mode: int) -> void:
	cursor_mode = mode
	queue_redraw()

func set_pressed(value: bool) -> void:
	pressed = value
	queue_redraw()

func _process(_delta: float) -> void:
	if visible:
		global_position = get_viewport().get_mouse_position() - size * 0.5
		queue_redraw()

func _draw() -> void:
	var accent := Color(0.24, 0.96, 0.86)
	var secondary := Color(0.72, 0.36, 1.0)
	if pressed:
		accent = Color(1.0, 0.78, 0.22)
	match cursor_mode:
		CursorMode.PAINT:
			draw_circle(Vector2(16, 16), 8.0, Color(0.04, 0.10, 0.15, 0.92))
			draw_arc(Vector2(16, 16), 8.0, 0.0, TAU, 24, accent, 2.0)
			draw_line(Vector2(13, 19), Vector2(21, 11), accent, 2.0)
			draw_line(Vector2(12, 21), Vector2(14, 19), secondary, 2.0)
		CursorMode.EYEDROPPER:
			draw_circle(Vector2(13, 13), 6.0, Color(0.04, 0.10, 0.15, 0.94))
			draw_arc(Vector2(13, 13), 6.0, 0.0, TAU, 24, accent, 2.0)
			draw_line(Vector2(17, 17), Vector2(24, 24), accent, 3.0)
			draw_circle(Vector2(13, 13), 2.0, secondary)
		_:
			var points := PackedVector2Array([Vector2(16, 2), Vector2(26, 14), Vector2(18, 14), Vector2(22, 27), Vector2(11, 15), Vector2(15, 15)])
			draw_colored_polygon(points, Color(0.03, 0.08, 0.13, 0.96))
			draw_polyline(points, accent, 2.0, true)
			draw_line(Vector2(18, 14), Vector2(24, 20), secondary, 2.0)
