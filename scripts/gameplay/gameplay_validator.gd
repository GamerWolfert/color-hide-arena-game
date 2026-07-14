extends Node

func validate_gameplay(arena: Node) -> bool:
	var failures: Array[String] = []
	var map := arena.get_node_or_null("TrainingMap")
	if map == null or map.name != "TrainingMap" or str(map.get_meta("gameplay_map", "")) != "Candy Workshop":
		failures.append("Candy Workshop is niet geladen als gameplaymap")
	elif int(map.get_meta("candy_prop_count", 0)) < 40:
		failures.append("Candy Workshop bevat minder dan 40 zichtbare props")
	var player := arena.get_node_or_null("Player")
	if player == null:
		failures.append("Speler ontbreekt")
	var round_manager := arena.get_node_or_null("RoundManager")
	if round_manager == null:
		failures.append("RoundManager ontbreekt")
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor == null:
		failures.append("CursorManager ontbreekt")
	var roster := get_node_or_null("/root/MatchRoster")
	if roster == null:
		failures.append("MatchRoster ontbreekt")
	else:
		if player and roster.get_id_for_node(player).is_empty():
			failures.append("Speler is niet in MatchRoster geregistreerd")
		var counts: Dictionary = roster.get_role_counts()
		if int(counts.get("seekers", 0)) < 1:
			failures.append("Geen echte Seeker-bot geregistreerd")
	var hud := arena.get_node_or_null("HUD")
	if hud == null:
		failures.append("Gameplay HUD ontbreekt")
	else:
		if hud.get("_pose_wheel") == null:
			failures.append("PoseWheel ontbreekt")
		if hud.get("paint_ui") == null:
			failures.append("PaintMode ontbreekt")
	if failures.is_empty():
		print("GAMEPLAY_VALIDATION_OK map=Candy Workshop player=1 seeker=1 pose_wheel=1 paint_mode=1")
		return true
	for failure in failures:
		push_error("GAMEPLAY_VALIDATION: %s" % failure)
	return false
