extends Control

var _move_start := Vector2.ZERO
var _look_start := Vector2.ZERO
var _move_touch := -1
var _look_touch := -1

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    var input_service := get_node_or_null("/root/InputService")
    if input_service and input_service.touch_input_blocked:
        input_service.clear_touch_input()
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < size.x * 0.48 and _move_touch == -1:
                _move_touch = event.index
                _move_start = event.position
            elif event.position.x >= size.x * 0.48 and _look_touch == -1:
                _look_touch = event.index
                _look_start = event.position
        elif event.index == _move_touch:
            _move_touch = -1
            _set_move(Vector2.ZERO)
        elif event.index == _look_touch:
            _look_touch = -1
            _set_look(Vector2.ZERO)
    elif event is InputEventScreenDrag:
        if event.index == _move_touch:
            _set_move((event.position - _move_start) / 100.0)
        elif event.index == _look_touch:
            _set_look((event.position - _look_start) / 80.0)

func _set_move(value: Vector2) -> void:
    var input_service := get_node_or_null("/root/InputService")
    if input_service:
        input_service.set_touch_move(value)
    queue_redraw()

func _set_look(value: Vector2) -> void:
    var input_service := get_node_or_null("/root/InputService")
    if input_service:
        input_service.set_touch_look(value)

func _draw() -> void:
    if _move_touch != -1:
        draw_circle(_move_start, 74.0, Color(0.12, 0.85, 0.78, 0.18))
        draw_circle(_move_start, 28.0, Color(0.18, 0.95, 0.72, 0.42))
    if _look_touch != -1:
        draw_circle(_look_start, 62.0, Color(0.55, 0.25, 0.92, 0.18))
