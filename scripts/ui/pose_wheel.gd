extends Control

signal pose_selected(index: int, pose_name: String)
signal closed

const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")
const SEGMENT_COUNT := 8
const POSE_LABELS := ["Staan", "Zitten", "Rugligging", "Buikligging", "Armen omhoog", "Hurken", "Leunen", "Zwaaien"]

var player: Node
var selected_index := -1
var _center := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func open(next_player: Node) -> void:
	player = next_player
	selected_index = -1
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var input_service := get_node_or_null("/root/InputService")
	if input_service:
		input_service.set_touch_input_blocked(true)
	if player and player.has_method("set_menu_input_locked"):
		player.set_menu_input_locked(true)
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor:
		cursor.set_mode(cursor.CursorMode.UI)
	queue_redraw()

func close_wheel() -> void:
	visible = false
	selected_index = -1
	var input_service := get_node_or_null("/root/InputService")
	if input_service:
		input_service.set_touch_input_blocked(false)
	if player and player.has_method("set_menu_input_locked"):
		player.set_menu_input_locked(false)
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor:
		cursor.set_mode(cursor.CursorMode.GAMEPLAY)
	closed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_selection(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _is_cancel_position(event.position):
				close_wheel()
			elif selected_index >= 0:
				_confirm_selection()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			close_wheel()
	elif event is InputEventScreenTouch and event.pressed:
		_update_selection(event.position)
		if _is_cancel_position(event.position):
			close_wheel()
		elif selected_index >= 0:
			_confirm_selection()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_wheel()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _update_selection(mouse_position: Vector2) -> void:
	_center = size * 0.5
	var offset := mouse_position - _center
	if offset.length() < 50.0 or offset.length() > 190.0:
		selected_index = -1
	else:
		var angle := atan2(offset.y, offset.x) + PI * 0.5
		if angle < 0.0:
			angle += TAU
		selected_index = posmod(int(floor((angle + PI / SEGMENT_COUNT) / (TAU / SEGMENT_COUNT))), SEGMENT_COUNT)
	queue_redraw()

func _is_cancel_position(mouse_position: Vector2) -> bool:
	return mouse_position.distance_to(size * 0.5) <= 45.0

func _confirm_selection() -> void:
	if selected_index < 0 or selected_index >= SEGMENT_COUNT:
		return
	var pose_name: String = PoseManagerScript.POSE_NAMES[selected_index]
	if player and player.pose_manager:
		player.pose_manager.set_pose(selected_index)
	pose_selected.emit(selected_index, pose_name)
	close_wheel()

func _draw() -> void:
	_center = size * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.005, 0.012, 0.03, 0.46), true)
	draw_circle(_center, 198.0, Color(0.015, 0.025, 0.055, 0.96))
	draw_arc(_center, 198.0, 0.0, TAU, 96, Color(0.18, 0.86, 0.78, 0.9), 2.0)
	for index in range(SEGMENT_COUNT):
		var start_angle := -PI * 0.5 + index * TAU / SEGMENT_COUNT - 0.018
		var end_angle := -PI * 0.5 + (index + 1) * TAU / SEGMENT_COUNT + 0.018
		var color := Color(0.05, 0.10, 0.16, 0.96)
		if index == selected_index:
			color = Color(0.43, 0.10, 0.62, 1.0)
		var points := PackedVector2Array([_center])
		for point_index in range(13):
			points.append(_center + Vector2.from_angle(lerpf(start_angle, end_angle, float(point_index) / 12.0)) * 184.0)
		draw_colored_polygon(points, color)
		draw_arc(_center, 184.0, start_angle, end_angle, 18, Color(0.20, 0.78, 0.76, 0.65), 1.0)
		_draw_pose_icon(_center + Vector2.from_angle((start_angle + end_angle) * 0.5) * 126.0, index, index == selected_index)
		_draw_pose_label(_center + Vector2.from_angle((start_angle + end_angle) * 0.5) * 162.0, POSE_LABELS[index])
	draw_circle(_center, 42.0, Color(0.03, 0.055, 0.09, 1.0))
	draw_arc(_center, 42.0, 0.0, TAU, 36, Color(0.96, 0.76, 0.22, 0.9), 2.0)
	draw_line(_center + Vector2(-12, -12), _center + Vector2(12, 12), Color.WHITE, 3.0)
	draw_line(_center + Vector2(12, -12), _center + Vector2(-12, 12), Color.WHITE, 3.0)

func _draw_pose_icon(center: Vector2, pose_index: int, highlighted: bool) -> void:
	var color := Color(1.0, 0.96, 0.88) if highlighted else Color(0.86, 0.90, 0.88)
	var head := center + Vector2(0, -13)
	var torso := center + Vector2(0, 3)
	var left_hand := center + Vector2(-17, 8)
	var right_hand := center + Vector2(17, 8)
	var left_foot := center + Vector2(-9, 25)
	var right_foot := center + Vector2(9, 25)
	match pose_index:
		1:
			torso.y += 4
			left_foot = center + Vector2(-16, 16)
			right_foot = center + Vector2(16, 16)
		2:
			head = center + Vector2(-19, 0)
			torso = center
			left_hand = center + Vector2(-5, -11)
			right_hand = center + Vector2(8, 11)
			left_foot = center + Vector2(20, -7)
			right_foot = center + Vector2(20, 7)
		3:
			head = center + Vector2(19, 0)
			torso = center
			left_hand = center + Vector2(-8, -10)
			right_hand = center + Vector2(-8, 10)
			left_foot = center + Vector2(-20, -7)
			right_foot = center + Vector2(-20, 7)
		4:
			left_hand = center + Vector2(-12, -22)
			right_hand = center + Vector2(12, -22)
		5:
			torso.y += 6
			head.y += 5
			left_foot = center + Vector2(-15, 20)
			right_foot = center + Vector2(15, 20)
		6:
			head += Vector2(7, 1)
			torso += Vector2(4, 2)
			left_foot += Vector2(8, 0)
			right_foot += Vector2(8, 0)
		7:
			right_hand = center + Vector2(12, -22)
			left_hand = center + Vector2(-18, 8)
	draw_circle(head, 7.5, color)
	draw_circle(torso, 9.5, color)
	draw_line(torso + Vector2(-4, 6), left_foot, color, 4.2, true)
	draw_line(torso + Vector2(4, 6), right_foot, color, 4.2, true)
	draw_line(torso + Vector2(-6, -2), left_hand, color, 3.6, true)
	draw_line(torso + Vector2(6, -2), right_hand, color, 3.6, true)

func _draw_pose_label(center: Vector2, value: String) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, center - Vector2(48, -4), value, HORIZONTAL_ALIGNMENT_CENTER, 96, 11, Color(0.92, 0.96, 1.0))
