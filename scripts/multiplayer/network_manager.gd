extends Node

const DEFAULT_PORT := 24590
const MAX_CLIENTS := 16
const MATCH_MANAGER_SCRIPT := preload("res://scripts/multiplayer/server_match_manager.gd")

signal network_started(role: String)
signal network_stopped
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal connection_failed(message: String)
signal connection_succeeded
signal match_manager_ready(manager: Node)

var is_networked := false
var is_server := false
var server_address := ""
var server_port := DEFAULT_PORT
var local_peer_id := 1
var match_manager: Node

var _local_player: Node
var _gameplay_root: Node
var _send_accumulator := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	call_deferred("_bootstrap_command_line")

func _physics_process(delta: float) -> void:
	if not is_networked or not _local_player or not is_instance_valid(_local_player) or not match_manager:
		return
	_send_accumulator += delta
	if _send_accumulator < 0.05:
		return
	_send_accumulator = 0.0
	var payload := _collect_local_state()
	if is_server:
		match_manager.server_update_local_state(1, payload)
	else:
		match_manager.submit_input.rpc_id(1, payload)

func start_server(port: int = DEFAULT_PORT) -> bool:
	stop_network()
	var enet := ENetMultiplayerPeer.new()
	var result := enet.create_server(port, MAX_CLIENTS)
	if result != OK:
		connection_failed.emit("Server starten mislukt: %s" % error_string(result))
		return false
	server_port = port
	server_address = "0.0.0.0"
	is_server = true
	_set_peer(enet)
	_ensure_match_manager()
	match_manager.start_authoritative_match()
	print("NETWORK_SERVER_READY port=%d" % server_port)
	network_started.emit("server")
	return true

func start_client(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> bool:
	stop_network()
	var enet := ENetMultiplayerPeer.new()
	var result := enet.create_client(address, port)
	if result != OK:
		connection_failed.emit("Verbinden mislukt: %s" % error_string(result))
		return false
	server_address = address
	server_port = port
	is_server = false
	_set_peer(enet)
	_ensure_match_manager()
	print("NETWORK_CLIENT_CONNECTING address=%s port=%d" % [server_address, server_port])
	network_started.emit("client")
	return true

func stop_network() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_networked = false
	is_server = false
	local_peer_id = 1
	if match_manager:
		match_manager.stop_match()
		match_manager.queue_free()
		match_manager = null
	network_stopped.emit()

func register_game_world(root: Node, player: Node) -> void:
	_gameplay_root = root
	_local_player = player
	_ensure_match_manager()
	match_manager.bind_gameplay_world(root, player)

func request_scan(direction: Vector3) -> void:
	if not is_networked or not match_manager:
		return
	if is_server:
		match_manager.server_request_scan(1, direction)
	else:
		match_manager.request_scan.rpc_id(1, direction)

func request_appearance(part_name: String, color: Color, pose_index: int) -> void:
	if not is_networked or not match_manager:
		return
	if is_server:
		match_manager.server_request_appearance(1, part_name, color, pose_index)
	else:
		match_manager.request_appearance.rpc_id(1, part_name, color.to_html(true), pose_index)

func get_status_text() -> String:
	if not is_networked:
		return "Offline"
	if is_server:
		return "Server online  %d" % multiplayer.get_peers().size()
	return "Verbonden met %s" % server_address

func _set_peer(next_peer: MultiplayerPeer) -> void:
	multiplayer.multiplayer_peer = next_peer
	is_networked = true
	local_peer_id = multiplayer.get_unique_id()

func _ensure_match_manager() -> void:
	if match_manager and is_instance_valid(match_manager):
		return
	match_manager = MATCH_MANAGER_SCRIPT.new()
	match_manager.name = "ServerMatchManager"
	add_child(match_manager)
	match_manager.setup(self)
	match_manager_ready.emit(match_manager)

func _collect_local_state() -> Dictionary:
	var input_service := get_node_or_null("/root/InputService")
	var move: Vector2 = input_service.get_move_vector() if input_service else Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var pose_index := 0
	if _local_player.get("pose_index") != null:
		pose_index = int(_local_player.pose_index)
	var colors: Dictionary = {}
	if _local_player.has_method("get_body_part_names") and _local_player.has_method("get_body_part_color"):
		for part_name in _local_player.get_body_part_names():
			colors[part_name] = _local_player.get_body_part_color(part_name).to_html(true)
	return {
		"move": move,
		"yaw": _local_player.get_node("YawRoot").rotation.y,
		"pitch": _local_player.get_node("YawRoot/PitchRoot").rotation.x,
		"position": _local_player.global_position,
		"pose": pose_index,
		"colors": colors,
		"sprint": Input.is_action_pressed("sprint"),
		"crouch": Input.is_action_pressed("crouch")
	}

func _on_peer_connected(peer_id: int) -> void:
	print("NETWORK_PEER_CONNECTED peer=%d" % peer_id)
	peer_joined.emit(peer_id)
	if is_server and match_manager:
		match_manager.register_peer(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("NETWORK_PEER_DISCONNECTED peer=%d" % peer_id)
	peer_left.emit(peer_id)
	if match_manager:
		match_manager.remove_peer(peer_id)

func _on_connected_to_server() -> void:
	local_peer_id = multiplayer.get_unique_id()
	connection_succeeded.emit()
	if match_manager:
		match_manager.send_hello()
	print("NETWORK_CLIENT_CONNECTED peer=%d" % local_peer_id)

func _on_connection_failed() -> void:
	connection_failed.emit("De verbinding met de server is mislukt.")

func _bootstrap_command_line() -> void:
	var args := OS.get_cmdline_user_args()
	var port := DEFAULT_PORT
	var join_address := ""
	var should_host := false
	var should_server := false
	for arg in args:
		if arg == "--server" or arg == "--dedicated-server":
			should_server = true
		elif arg == "--host":
			should_host = true
		elif arg.begins_with("--port="):
			port = int(arg.get_slice("=", 1))
		elif arg.begins_with("--join="):
			join_address = arg.get_slice("=", 1)
		elif arg == "--join":
			join_address = "127.0.0.1"
	if should_server or should_host:
		if not is_networked:
			start_server(port)
	elif not join_address.is_empty() and not is_networked:
		start_client(join_address, port)
