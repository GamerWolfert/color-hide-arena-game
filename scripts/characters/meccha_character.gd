extends Node3D

const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")

var body_parts: Dictionary = {}
var pose_manager: Node
var _default_color := Color(0.88, 0.86, 0.79)

func _ready() -> void:
	_build_body()
	pose_manager = PoseManagerScript.new()
	pose_manager.name = "PoseManager"
	add_child(pose_manager)
	pose_manager.setup(body_parts)
	apply_color(_default_color)

func get_body_parts() -> Dictionary:
	return body_parts

func get_pose_manager() -> Node:
	return pose_manager

func apply_color(color: Color) -> void:
	for part_name in body_parts:
		_set_part_material(body_parts[part_name], color)

func set_body_part_style(part_name: String, color: Color, metallic := 0.0, roughness := 0.78) -> void:
	var part: MeshInstance3D = body_parts.get(part_name)
	if part == null:
		return
	var material := _material(color, metallic, roughness)
	part.material_override = material
	for child in part.get_children():
		if child is MeshInstance3D and child.has_meta("camo_detail"):
			child.material_override = _material(color, metallic, roughness)

func get_body_part_color(part_name: String) -> Color:
	var part: MeshInstance3D = body_parts.get(part_name)
	if part and part.material_override is StandardMaterial3D:
		return part.material_override.albedo_color
	return _default_color

func _build_body() -> void:
	var root := Node3D.new()
	root.name = "BodyParts"
	add_child(root)
	# Overlapping soft meshes keep the six paint zones while removing visible joints.
	_add_part(root, "Torso", Vector3(0, 1.03, 0), 0.48, 1.28, false, Vector3(0.82, 1.0, 0.62))
	_add_part(root, "Head", Vector3(0, 1.83, 0), 0.43, 0.86, true, Vector3(1.0, 1.0, 0.96))
	_add_part(root, "LeftArm", Vector3(-0.49, 1.12, 0), 0.18, 0.94, false, Vector3(0.88, 1.0, 0.88))
	_add_part(root, "RightArm", Vector3(0.49, 1.12, 0), 0.18, 0.94, false, Vector3(0.88, 1.0, 0.88))
	_add_part(root, "LeftLeg", Vector3(-0.21, 0.43, -0.015), 0.20, 0.92, false, Vector3(0.94, 1.0, 1.02))
	_add_part(root, "RightLeg", Vector3(0.21, 0.43, -0.015), 0.20, 0.92, false, Vector3(0.94, 1.0, 1.02))

func _add_part(root: Node3D, part_name: String, position_value: Vector3, radius: float, height: float, sphere := false, scale_value := Vector3.ONE) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.position = position_value
	part.scale = scale_value
	part.set_meta("body_part", part_name)
	part.set_meta("camo_detail", true)
	if sphere:
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = radius
		sphere_mesh.height = height
		sphere_mesh.radial_segments = 32
		sphere_mesh.rings = 16
		part.mesh = sphere_mesh
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = height
		capsule.radial_segments = 24
		capsule.rings = 8
		part.mesh = capsule
	root.add_child(part)
	body_parts[part_name] = part

func _set_part_material(part: MeshInstance3D, color: Color) -> void:
	part.material_override = _material(color, 0.0, 0.76)
	for child in part.get_children():
		if child is MeshInstance3D and bool(child.get_meta("camo_detail", false)):
			child.material_override = _material(color, 0.0, 0.76)

func _material(color: Color, metallic: float, roughness: float, emission := Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = clampf(metallic, 0.0, 1.0)
	material.roughness = clampf(roughness, 0.05, 1.0)
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 1.4
	return material
