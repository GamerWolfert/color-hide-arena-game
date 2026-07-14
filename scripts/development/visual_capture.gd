extends SceneTree

const TRAINING_SCENE := preload("res://scenes/gameplay/TrainingArena.tscn")
const OUTPUT_DIR := "res://artifacts/visual_validation"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var arena := TRAINING_SCENE.instantiate()
	root.add_child(arena)
	await _settle(18)
	var player: Node3D = arena.get_node("Player")
	var hud: CanvasLayer = arena.get_node("HUD")
	if hud._tutorial_toast:
		hud._tutorial_toast.visible = false
	var yaw_root: Node3D = player.get_node("YawRoot")
	var pitch_root: Node3D = player.get_node("YawRoot/PitchRoot")
	var seekers: Array = arena.seeker_bots
	if not seekers.is_empty() and is_instance_valid(seekers[0]):
		seekers[0].global_position = player.global_position + Vector3(7.0, 0.0, -4.0)
	yaw_root.rotation.y = 0.0
	pitch_root.rotation.x = deg_to_rad(-12.0)
	await _settle(5)
	_capture("01_normal_gameplay.png")
	_capture("03_compact_timer_1_hider_1_seeker.png")
	if not seekers.is_empty() and is_instance_valid(seekers[0]):
		seekers[0].visible = false
	_capture("02_character_back.png")
	yaw_root.rotation.y = PI
	await _settle(4)
	_capture("02_character_front.png")
	if not seekers.is_empty() and is_instance_valid(seekers[0]):
		seekers[0].visible = true
	yaw_root.rotation.y = 0.0
	hud._toggle_pose_menu()
	hud._pose_wheel.selected_index = 2
	hud._pose_wheel.queue_redraw()
	Input.warp_mouse(Vector2(790, 360))
	await _settle(5)
	_capture("04_pose_wheel_open.png")
	hud._toggle_pose_menu()
	hud.paint_ui.toggle()
	await _settle(5)
	_capture("05_paint_mode_open.png")
	var apply_button := _find_button(hud.paint_ui, "Toepassen")
	if apply_button:
		Input.warp_mouse(apply_button.get_global_rect().get_center())
		var cursor := root.get_node_or_null("CursorManager")
		if cursor and cursor.has_method("set_hovered"):
			cursor.set_hovered(true)
	await _settle(5)
	_capture("06_game_cursor_over_button.png")
	hud.paint_ui.close()
	if not seekers.is_empty() and is_instance_valid(seekers[0]):
		seekers[0].global_position = player.global_position + Vector3(2.4, 0.0, -4.0)
		seekers[0].look_at(player.global_position, Vector3.UP)
	await _settle(5)
	_capture("07_seeker_bot_visible.png")
	var round_manager: Node = arena.get_node("RoundManager")
	round_manager.timer.stop()
	player.set_hider(true)
	round_manager._set_state(round_manager.RoundState.SEARCHING, 20, "Infection-test")
	round_manager.register_scan(true, player, 100.0)
	await _settle(5)
	_capture("08_infection_result.png")
	print("VISUAL_CAPTURE_COMPLETE dir=%s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	Input.set_custom_mouse_cursor(null)
	arena.queue_free()
	await _settle(3)
	quit()

func _settle(frames: int) -> void:
	for _index in range(frames):
		await process_frame

func _capture(file_name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Screenshot opslaan mislukt: %s" % path)
	else:
		print("VISUAL_CAPTURE saved=%s" % path)

func _find_button(node: Node, button_text: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		if child is Button and child.text == button_text:
			return child
	return null
