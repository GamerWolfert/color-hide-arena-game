extends SceneTree

const TRAINING_SCENE := preload("res://scenes/gameplay/TrainingArena.tscn")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := TRAINING_SCENE.instantiate()
	root.add_child(arena)
	await _frames(24)
	var player: CharacterBody3D = arena.get_node("Player")
	var hud: CanvasLayer = arena.get_node("HUD")
	var round_manager: Node = arena.get_node("RoundManager")
	var roster := root.get_node_or_null("MatchRoster")
	_check(arena.seeker_bots.size() == 1, "precies een echte Seeker-bot")
	_check(roster != null and roster.get_participant_count() == 2, "roster bevat speler en bot")
	if roster:
		var counts: Dictionary = roster.get_role_counts()
		_check(int(counts.get("hiders", 0)) == 1 and int(counts.get("seekers", 0)) == 1, "HUD-roster start met 1 Hider en 1 Seeker")

	hud._toggle_pose_menu()
	await _frames(2)
	var wheel: Control = hud._pose_wheel
	_check(wheel.visible and player.menu_input_locked, "posewiel blokkeert lokale gameplayinput")
	wheel.selected_index = 4
	wheel._confirm_selection()
	await _frames(2)
	_check(player.pose_index == 4 and not player.menu_input_locked, "posekeuze wordt toegepast en sluit correct")
	for pose_index in range(8):
		player.pose_manager.set_pose(pose_index)
		await _frames(2)
		for body_part in player.body_parts.values():
			_check(body_part.scale.length() > 0.2, "pose %d behoudt alle lichaamsdelen" % pose_index)
	player.pose_manager.set_pose(0)

	hud.paint_ui.toggle()
	await _frames(2)
	_check(hud.paint_ui.visible and player.menu_input_locked, "Paint Mode is klikbaar en blokkeert camera/input")
	var sample_ray: RayCast3D = player.get_node("YawRoot/PitchRoot/SpringArm3D/Camera3D/RayCast3D")
	var sample_target: Node3D = arena.get_node("TrainingMap/SugarStepB")
	var original_ray_target := sample_ray.target_position
	sample_ray.target_position = sample_ray.to_local(sample_target.global_position)
	await physics_frame
	await physics_frame
	player.sample_color()
	print("EYEDROPPER_TEST colliding=%s collider=%s color=%s" % [sample_ray.is_colliding(), sample_ray.get_collider(), player.sampled_color])
	_check(sample_ray.is_colliding() and player.last_surface_distance < 99.0 and not player.sampled_color.is_equal_approx(Color.WHITE), "eyedropper kopieert de geraakte oppervlakkleur")
	sample_ray.target_position = original_ray_target
	hud.paint_ui.manager.set_selected_part("Torso")
	hud.paint_ui.manager.set_color(player.sampled_color)
	hud.paint_ui.manager.apply()
	_check(player.get_body_part_color("Torso").is_equal_approx(player.sampled_color), "Paint Mode past kleur op gekozen lichaamsdeel toe")
	hud.paint_ui.close()
	await _frames(3)

	var seeker: CharacterBody3D = arena.seeker_bots[0] if not arena.seeker_bots.is_empty() else null
	if seeker:
		round_manager.timer.stop()
		player.set_hider(true)
		player.global_position = Vector3(0, 1.2, 5.0)
		seeker.global_position = Vector3(0, 1.2, 8.0)
		round_manager._set_state(round_manager.RoundState.SEARCHING, 20, "Acceptatietest")
		await _frames(5)
		seeker._scan_nearby_hiders()
		await _frames(5)
		_check(not player.is_hider, "Seeker-bot converteert gevonden Hider naar Seeker")
		_check(round_manager.state == round_manager.RoundState.RESULTS, "Infection-ronde eindigt na laatste Hider")
		if roster:
			var final_counts: Dictionary = roster.get_role_counts()
			_check(int(final_counts.get("hiders", -1)) == 0 and int(final_counts.get("seekers", -1)) == 2, "roster en HUD-aantallen volgen Infection-conversie")

	if failures.is_empty():
		print("GAMEPLAY_ACCEPTANCE_OK pose=1 paint=1 eyedropper=1 infection=1 round_end=1 roster=1")
	else:
		for failure in failures:
			push_error("GAMEPLAY_ACCEPTANCE_FAIL: %s" % failure)
	Input.set_custom_mouse_cursor(null)
	arena.queue_free()
	await _frames(3)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)

func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
