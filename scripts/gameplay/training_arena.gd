extends Node3D

const HiderBotScript := preload("res://scripts/characters/hider_bot.gd")
const SeekerBotScript := preload("res://scripts/characters/seeker_bot.gd")
const MobileControlsScript := preload("res://scripts/input/mobile_controls.gd")
const DebugVisualsScript := preload("res://scripts/ui/debug_visuals.gd")

@onready var player := $Player
@onready var hud := $HUD
@onready var pause_menu := $PauseMenu
@onready var round_manager := $RoundManager
@onready var training_map := $TrainingMap

var hider_bots: Array = []
var seeker_bots: Array = []

func _ready() -> void:
	var network := get_node_or_null("/root/NetworkManager")
	var networked: bool = network != null and network.is_networked
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor:
		cursor.set_mode(cursor.CursorMode.GAMEPLAY)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_add_mobile_controls_if_needed()
	if round_manager.has_method("set_network_authoritative"):
		round_manager.set_network_authoritative(networked)
	if not networked:
		_spawn_bots()
	hud.bind_player(player)
	if networked:
		network.register_game_world(self, player)
		hud.bind_round_manager(network.match_manager)
		player.seeker_scanned.connect(func(_found, _target, _energy): network.request_scan(-player.camera.global_transform.basis.z))
		player.pose_changed.connect(func(_pose_name): network.request_appearance(player.get_selected_part_name(), player.get_body_part_color(player.get_selected_part_name()), player.pose_index))
		if hud.paint_ui and hud.paint_ui.has_signal("paint_applied"):
			hud.paint_ui.paint_applied.connect(func(part_name, color): network.request_appearance(part_name, color, player.pose_index))
	else:
		hud.bind_round_manager(round_manager)
		hud._on_phase_changed(round_manager._phase_name(), round_manager.seconds_left)
		hud._on_hider_count_changed(round_manager.remaining_hiders, round_manager.total_hiders)
		player.seeker_scanned.connect(round_manager.register_scan)
		pause_menu.restart_requested.connect(round_manager.restart_round)

func _add_mobile_controls_if_needed() -> void:
	var device := get_node_or_null("/root/DeviceService")
	var settings := get_node_or_null("/root/SettingsService")
	var force_mobile: bool = settings != null and settings.force_mobile_ui_on_desktop
	if device == null or (not force_mobile and not device.is_mobile() and not device.has_touchscreen()):
		return
	var layer := CanvasLayer.new()
	layer.name = "MobileControlsLayer"
	layer.layer = 0
	add_child(layer)
	var controls := MobileControlsScript.new()
	controls.name = "MobileControls"
	layer.add_child(controls)

func _spawn_bots() -> void:
	var hide_spots: Array = training_map.get_hide_spots()
	for i in range(4):
		var bot := CharacterBody3D.new()
		bot.name = "HiderBot%d" % (i + 1)
		bot.script = HiderBotScript
		add_child(bot)
		bot.setup(hide_spots, i)
		hider_bots.append(bot)
	var patrol_points: Array = training_map.get_patrol_points()
	var seeker := CharacterBody3D.new()
	seeker.name = "SeekerBot"
	seeker.script = SeekerBotScript
	add_child(seeker)
	seeker.setup(patrol_points, hider_bots)
	seeker.bot_found_hider.connect(func(target): round_manager.register_scan(true, target, 100.0))
	seeker_bots.append(seeker)
	round_manager.set_hiders(hider_bots)
	round_manager.set_seekers(seeker_bots)
	if OS.is_debug_build():
		var debug_visuals := DebugVisualsScript.new()
		debug_visuals.name = "DebugVisuals"
		add_child(debug_visuals)
		debug_visuals.setup([player] + hider_bots + seeker_bots)
