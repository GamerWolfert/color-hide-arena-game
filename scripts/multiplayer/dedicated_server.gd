extends Node

@export var port := 24590

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var resolved_port := _command_line_port()
	var network := get_node_or_null("/root/NetworkManager")
	if network and network.is_networked and network.is_server:
		print("DEDICATED_SERVER_READY port=%d" % resolved_port)
		return
	if network and network.start_server(resolved_port):
		print("DEDICATED_SERVER_READY port=%d" % resolved_port)
	else:
		push_error("Dedicated server kon niet starten")

func _command_line_port() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--port="):
			return clampi(int(arg.get_slice("=", 1)), 1024, 65535)
	return port
