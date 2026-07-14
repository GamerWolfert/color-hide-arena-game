extends CanvasLayer

enum CursorMode { GAMEPLAY, UI, PAINT, EYEDROPPER }

const CursorScene := preload("res://scenes/ui/game_cursor.tscn")

var current_mode: CursorMode = CursorMode.GAMEPLAY
var game_cursor: Control
var _transparent_cursor: ImageTexture

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_make_transparent_os_cursor()
	game_cursor = CursorScene.instantiate()
	game_cursor.name = "GameCursor"
	game_cursor.visible = false
	add_child(game_cursor)
	get_viewport().size_changed.connect(_refresh_cursor_position)
	set_mode(CursorMode.GAMEPLAY)

func set_mode(mode: CursorMode) -> void:
	current_mode = mode
	var mobile := _is_mobile()
	if mode == CursorMode.GAMEPLAY or mobile:
		game_cursor.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if not mobile else Input.MOUSE_MODE_VISIBLE)
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	game_cursor.visible = true
	game_cursor.set_cursor_mode(_cursor_visual_mode(mode))
	_refresh_cursor_position()

func get_mode() -> CursorMode:
	return current_mode

func is_ui_mode() -> bool:
	return current_mode != CursorMode.GAMEPLAY

func set_pressed(value: bool) -> void:
	if game_cursor and is_instance_valid(game_cursor):
		game_cursor.set_pressed(value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		set_pressed(event.pressed)

func _cursor_visual_mode(mode: CursorMode) -> int:
	match mode:
		CursorMode.PAINT:
			return 1
		CursorMode.EYEDROPPER:
			return 2
		_:
			return 0

func _refresh_cursor_position() -> void:
	if game_cursor and is_instance_valid(game_cursor) and game_cursor.visible:
		game_cursor.global_position = get_viewport().get_mouse_position() - game_cursor.size * 0.5

func _make_transparent_os_cursor() -> void:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_transparent_cursor = ImageTexture.create_from_image(image)
	Input.set_custom_mouse_cursor(_transparent_cursor, Input.CURSOR_ARROW, Vector2.ZERO)

func _is_mobile() -> bool:
	var device := get_node_or_null("/root/DeviceService")
	return device != null and (device.is_mobile() or device.has_touchscreen())
