extends Node3D

const CHARACTER_SCENE := preload("res://scenes/characters/meccha_character.tscn")

var character: Node3D
var pose_manager: Node

func _ready() -> void:
	character = CHARACTER_SCENE.instantiate()
	character.name = "MecchaCharacter"
	add_child(character)

func apply_network_state(state: Dictionary) -> void:
	global_position = state.get("position", global_position)
	rotation.y = float(state.get("yaw", rotation.y))
	if not character:
		return
	var role := str(state.get("role", "HIDER"))
	if character.has_method("apply_color"):
		character.apply_color(Color(0.92, 0.18, 0.22) if role == "SEEKER" else Color(0.82, 0.84, 0.78))
	var manager: Node = character.get_pose_manager() if character.has_method("get_pose_manager") else null
	if manager:
		manager.set_pose(int(state.get("pose", 0)))
	var colors: Dictionary = state.get("colors", {})
	for part_name in colors.keys():
		if character.has_method("set_body_part_style"):
			character.set_body_part_style(str(part_name), Color.from_string(str(colors[part_name]), Color.WHITE))
