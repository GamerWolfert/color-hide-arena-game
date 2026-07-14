extends CharacterBody3D

const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")

signal found(bot: Node)

@export var bot_id := 0

var hidden_alive := true
var camouflage_percent := 0.0
var target_color := Color.WHITE
var pose_name := "Normaal"
var hide_spot: Marker3D
var body_parts := {}
var pose_manager: Node
var infected := false
var alerted := false

func _ready() -> void:
	add_to_group("hiders")
	_build_body()

func _physics_process(_delta: float) -> void:
	if not hidden_alive:
		return
	var nearest := 999.0
	for seeker in get_tree().get_nodes_in_group("seekers"):
		if is_instance_valid(seeker):
			nearest = minf(nearest, global_position.distance_to(seeker.global_position))
	if nearest < 4.5 and not alerted:
		alerted = true
		if pose_manager:
			pose_manager.set_pose_by_name("Hurken")
		camouflage_percent = maxf(camouflage_percent - 4.0, 0.0)
	elif nearest > 6.0:
		alerted = false

func setup(spots: Array, index: int) -> void:
	bot_id = index
	if spots.is_empty():
		return
	hide_spot = spots[index % spots.size()]
	global_position = hide_spot.global_position
	rotation.y = hide_spot.rotation.y
	target_color = hide_spot.get_meta("surface_color", Color.WHITE)
	pose_name = hide_spot.get_meta("pose", "Leunen")
	_paint_all(target_color)
	if pose_manager:
		pose_manager.set_pose_by_name(pose_name)
	camouflage_percent = float(hide_spot.get_meta("camouflage", 86.0))
	set_meta("surface_color", target_color)

func is_hidden_alive() -> bool:
	return hidden_alive

func mark_found() -> void:
	if not hidden_alive:
		return
	hidden_alive = false
	infected = false
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	found.emit(self)

func convert_to_seeker() -> void:
	if not hidden_alive:
		return
	hidden_alive = false
	infected = true
	visible = true
	remove_from_group("hiders")
	add_to_group("seekers")
	_paint_all(Color(0.88, 0.18, 0.24))
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	found.emit(self)

func reset_for_round() -> void:
	hidden_alive = true
	infected = false
	alerted = false
	visible = true
	remove_from_group("seekers")
	add_to_group("hiders")
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	if hide_spot:
		global_position = hide_spot.global_position
		rotation.y = hide_spot.rotation.y
		target_color = hide_spot.get_meta("surface_color", Color.WHITE)
		pose_name = hide_spot.get_meta("pose", "Leunen")
		_paint_all(target_color)
		if pose_manager:
			pose_manager.set_pose_by_name(pose_name)
		camouflage_percent = float(hide_spot.get_meta("camouflage", 86.0))

func get_camouflage_percent() -> float:
	return camouflage_percent if hidden_alive else 0.0

func _build_body() -> void:
	_add_part("Torso", Vector3(0, 1.05, 0), Vector3(0.72, 0.90, 0.34))
	_add_part("Head", Vector3(0, 1.70, 0), Vector3(0.42, 0.42, 0.42))
	_add_part("LeftArm", Vector3(-0.55, 1.10, 0), Vector3(0.22, 0.82, 0.22))
	_add_part("RightArm", Vector3(0.55, 1.10, 0), Vector3(0.22, 0.82, 0.22))
	_add_part("LeftLeg", Vector3(-0.22, 0.42, 0), Vector3(0.26, 0.78, 0.26))
	_add_part("RightLeg", Vector3(0.22, 0.42, 0), Vector3(0.26, 0.78, 0.26))
	pose_manager = PoseManagerScript.new()
	pose_manager.name = "PoseManager"
	add_child(pose_manager)
	pose_manager.setup(body_parts)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	col.shape = shape
	add_child(col)

func _add_part(part_name: String, pos: Vector3, size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.position = pos
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	add_child(mesh)
	body_parts[part_name] = mesh

func _paint_all(color: Color) -> void:
	for part in body_parts.values():
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.82
		part.material_override = mat

func _apply_pose(next_pose: String) -> void:
	if pose_manager:
		pose_manager.set_pose_by_name(next_pose)
