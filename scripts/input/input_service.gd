extends Node

const DEFAULT_ACTIONS := [
    "move_forward", "move_backward", "move_left", "move_right", "jump",
    "sprint", "crouch", "action", "pause", "toggle_role", "sample_color",
    "paint_part", "next_body_part", "pose_next", "pose_previous", "pose_menu", "paint_mode",
    "eyedropper", "scanner_primary", "zoom_in", "zoom_out", "toggle_rotation_lock",
    "toggle_name_labels", "toggle_xray", "taunt"
]

var _touch_move := Vector2.ZERO
var _touch_look := Vector2.ZERO
var touch_input_blocked := false

func _ready() -> void:
    _ensure_actions()

func _ensure_actions() -> void:
    for action in DEFAULT_ACTIONS:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
    if InputMap.action_get_events("pose_previous").is_empty():
        _add_key("pose_previous", 69)
    if InputMap.action_get_events("paint_mode").is_empty():
        _add_key("paint_mode", 70)
    if InputMap.action_get_events("pose_menu").is_empty():
        _add_key("pose_menu", 80)
    if InputMap.action_get_events("eyedropper").is_empty():
        _add_mouse("eyedropper", MOUSE_BUTTON_MIDDLE)
    if InputMap.action_get_events("scanner_primary").is_empty():
        _add_mouse("scanner_primary", MOUSE_BUTTON_LEFT)
    if InputMap.action_get_events("zoom_in").is_empty():
        _add_key("zoom_in", 4194308)
    if InputMap.action_get_events("zoom_out").is_empty():
        _add_key("zoom_out", 4194309)
    if InputMap.action_get_events("toggle_rotation_lock").is_empty():
        _add_key("toggle_rotation_lock", 76)
    if InputMap.action_get_events("toggle_name_labels").is_empty():
        _add_key("toggle_name_labels", 4194310)
    if InputMap.action_get_events("toggle_xray").is_empty():
        _add_key("toggle_xray", 4194311)
    if InputMap.action_get_events("taunt").is_empty():
        _add_key("taunt", 84)

func get_move_vector() -> Vector2:
    var keyboard_move := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    if keyboard_move.length() > 0.01:
        return keyboard_move
    for device_id in Input.get_connected_joypads():
        var stick := Vector2(
            Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
            Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
        )
        if stick.length() > 0.16:
            return stick.limit_length(1.0)
    return _touch_move.limit_length(1.0)

func get_look_vector() -> Vector2:
    var action_look := Vector2(
        Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
        Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
    )
    if action_look.length() > 0.01:
        return action_look
    for device_id in Input.get_connected_joypads():
        var stick := Vector2(
            Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
            Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
        )
        if stick.length() > 0.16:
            return stick.limit_length(1.0)
    return _touch_look.limit_length(1.0)

func set_touch_move(value: Vector2) -> void:
    _touch_move = value.limit_length(1.0)

func set_touch_look(value: Vector2) -> void:
    _touch_look = value.limit_length(1.0)

func clear_touch_input() -> void:
    _touch_move = Vector2.ZERO
    _touch_look = Vector2.ZERO

func set_touch_input_blocked(blocked: bool) -> void:
    touch_input_blocked = blocked
    if blocked:
        clear_touch_input()

func reset_bindings() -> void:
    for action in DEFAULT_ACTIONS:
        if InputMap.has_action(action):
            InputMap.action_erase_events(action)
    _add_key("move_forward", 87)
    _add_key("move_backward", 83)
    _add_key("move_left", 65)
    _add_key("move_right", 68)
    _add_key("jump", 32)
    _add_key("sprint", 4194325)
    _add_key("crouch", 67)
    _add_key("crouch", 4194326)
    _add_mouse("action", MOUSE_BUTTON_LEFT)
    _add_key("pause", 4194305)
    _add_key("toggle_role", 82)
    _add_key("sample_color", 69)
    _add_key("paint_part", 70)
    _add_key("next_body_part", 4194306)
    _add_key("pose_next", 81)
    _add_key("pose_previous", 69)
    _add_key("pose_menu", 80)
    _add_key("paint_mode", 70)
    _add_mouse("eyedropper", MOUSE_BUTTON_MIDDLE)
    _add_mouse("scanner_primary", MOUSE_BUTTON_LEFT)
    _add_key("zoom_in", 4194308)
    _add_key("zoom_out", 4194309)
    _add_key("toggle_rotation_lock", 76)
    _add_key("toggle_name_labels", 4194310)
    _add_key("toggle_xray", 4194311)
    _add_key("taunt", 84)

func _add_key(action: String, physical_keycode: int) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = physical_keycode
    InputMap.action_add_event(action, event)

func _add_mouse(action: String, button_index: MouseButton) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var event := InputEventMouseButton.new()
    event.button_index = button_index
    InputMap.action_add_event(action, event)
