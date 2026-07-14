extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")
const GAMEPLAY_SCENE := "res://scenes/gameplay/TrainingArena.tscn"

var address_input: LineEdit
var port_input: SpinBox
var status_label: Label
var host_button: Button
var join_button: Button
var _transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor:
		cursor.set_mode(cursor.CursorMode.UI)
	UI_STYLE.apply_theme(self)
	_build()
	var network := get_node_or_null("/root/NetworkManager")
	if network:
		network.connection_succeeded.connect(_on_connection_succeeded)
		network.connection_failed.connect(_on_connection_failed)
		network.peer_joined.connect(func(peer_id): _set_status("Speler %d verbonden" % peer_id))
		network.peer_left.connect(func(peer_id): _set_status("Speler %d heeft verlaten" % peer_id))
	call_deferred("_handle_command_line_route")

func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.012, 0.02, 0.055)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310.0
	panel.offset_top = -245.0
	panel.offset_right = 310.0
	panel.offset_bottom = 245.0
	panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.025, 0.045, 0.09, 0.98), Color(0.12, 0.85, 0.80, 0.9)))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "MULTIPLAYER LOBBY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_STYLE.title(title, 30)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Authoritative Infection matches"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.35, 0.95, 0.86))
	box.add_child(subtitle)
	address_input = LineEdit.new()
	address_input.placeholder_text = "Serveradres, bijvoorbeeld 127.0.0.1"
	address_input.text = "127.0.0.1"
	box.add_child(address_input)
	port_input = SpinBox.new()
	port_input.min_value = 1024
	port_input.max_value = 65535
	port_input.step = 1
	port_input.value = 24590
	port_input.prefix = "Poort  "
	box.add_child(port_input)
	host_button = _button("Host match", _host_match, Color(0.10, 0.82, 0.78, 0.9))
	join_button = _button("Join match", _join_match, Color(0.55, 0.27, 0.95, 0.9))
	box.add_child(host_button)
	box.add_child(join_button)
	var dedicated := _button("Dedicated server-info", func(): _set_status("Start: dedicated_server.tscn -- --server --port=24590"), Color(0.95, 0.72, 0.22, 0.9))
	box.add_child(dedicated)
	status_label = Label.new()
	status_label.text = "Kies hosten of joinen. De server beslist over de match."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 52)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.78, 0.87, 0.96))
	box.add_child(status_label)
	box.add_child(_button("Terug", func(): _open_scene("res://scenes/menus/main_menu.tscn"), Color(0.12, 0.68, 0.90, 0.8)))
	host_button.grab_focus()

func _host_match() -> void:
	if _transitioning:
		return
	var network := get_node_or_null("/root/NetworkManager")
	if not network:
		_set_status("NetworkManager ontbreekt")
		return
	var port := int(port_input.value)
	if network.is_networked and network.is_server:
		_open_game()
		return
	if network.start_server(port):
		_set_status("Server actief. Match wordt gestart...")
		_open_game()

func _join_match() -> void:
	if _transitioning:
		return
	var network := get_node_or_null("/root/NetworkManager")
	if not network:
		_set_status("NetworkManager ontbreekt")
		return
	if network.is_networked and not network.is_server:
		_set_status("Verbinden...")
		return
	join_button.disabled = true
	host_button.disabled = true
	_set_status("Verbinden met server...")
	network.start_client(address_input.text.strip_edges(), int(port_input.value))

func _on_connection_succeeded() -> void:
	_set_status("Verbonden. Match wordt geladen...")
	_open_game()

func _on_connection_failed(message: String) -> void:
	host_button.disabled = false
	join_button.disabled = false
	_set_status(message)

func _open_game() -> void:
	if _transitioning:
		return
	_transitioning = true
	var scene_manager := get_node_or_null("/root/SceneManager")
	var changed := false
	if scene_manager:
		changed = scene_manager.change_scene(GAMEPLAY_SCENE, false)
	else:
		changed = get_tree().change_scene_to_file(GAMEPLAY_SCENE) == OK
	if not changed:
		_transitioning = false
		_set_status("Gameplay scene kon niet worden geladen")

func _handle_command_line_route() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--host" and get_node_or_null("/root/NetworkManager") and get_node("/root/NetworkManager").is_server:
			_open_game()
			return
		if arg.begins_with("--join="):
			if get_node_or_null("/root/NetworkManager") and not get_node("/root/NetworkManager").is_server:
				_set_status("Verbinden...")
			return

func _set_status(message: String) -> void:
	if status_label:
		status_label.text = message

func _button(text_value: String, callback: Callable, accent: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_stylebox_override("normal", UI_STYLE.button(Color(0.04, 0.09, 0.15, 0.96), accent))
	button.add_theme_stylebox_override("hover", UI_STYLE.button(Color(0.12, 0.06, 0.20, 0.98), Color(0.82, 0.42, 1.0, 1.0)))
	button.add_theme_stylebox_override("pressed", UI_STYLE.button(Color(0.08, 0.20, 0.20, 1.0), Color(0.20, 1.0, 0.82, 1.0)))
	button.pressed.connect(callback)
	return button

func _open_scene(path: String) -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.change_scene(path, false)
	else:
		get_tree().change_scene_to_file(path)
