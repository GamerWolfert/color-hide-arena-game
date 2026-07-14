extends Node3D

const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")

var body_parts: Dictionary = {}
var pose_manager: Node
var _default_color := Color(0.86, 0.84, 0.76)

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
	_add_part(root, "Torso", Vector3(0, 1.02, 0), 0.39, 1.06)
	_add_part(root, "Head", Vector3(0, 1.80, 0), 0.38, 0.76, true)
	_add_part(root, "LeftArm", Vector3(-0.56, 1.12, 0), 0.145, 0.86)
	_add_part(root, "RightArm", Vector3(0.56, 1.12, 0), 0.145, 0.86)
	_add_part(root, "LeftLeg", Vector3(-0.23, 0.43, 0), 0.18, 0.90)
	_add_part(root, "RightLeg", Vector3(0.23, 0.43, 0), 0.18, 0.90)
	_add_shoulders(root)

func _add_part(root: Node3D, part_name: String, position_value: Vector3, radius: float, height: float, sphere := false) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.position = position_value
	part.set_meta("body_part", part_name)
	part.set_meta("camo_detail", true)
	if sphere:
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = radius
		sphere_mesh.height = height
		part.mesh = sphere_mesh
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = radius
		capsule.height = height
		part.mesh = capsule
	root.add_child(part)
	body_parts[part_name] = part
	_add_soft_extremity(part, part_name)

func _add_soft_extremity(part: MeshInstance3D, part_name: String) -> void:
	if part_name == "LeftArm" or part_name == "RightArm":
		var hand := _sphere_detail("Hand", Vector3(0, -0.46, 0), 0.16, part_name)
		part.add_child(hand)
	elif part_name == "LeftLeg" or part_name == "RightLeg":
		var foot := _sphere_detail("Foot", Vector3(0, -0.50, -0.07), 0.19, part_name)
		foot.scale = Vector3(0.86, 0.58, 1.12)
		part.add_child(foot)
	elif part_name == "Head":
		var visor := _sphere_detail("FaceVisor", Vector3(0, -0.01, -0.34), 0.205, "visor")
		visor.scale = Vector3(1.0, 0.70, 0.22)
		var visor_material := _material(Color(0.035, 0.15, 0.18), 0.35, 0.20, Color(0.02, 0.50, 0.48))
		visor.material_override = visor_material
		visor.set_meta("camo_detail", false)
		part.add_child(visor)

func _sphere_detail(name_value: String, position_value: Vector3, radius: float, detail_id: String) -> MeshInstance3D:
	var detail := MeshInstance3D.new()
	detail.name = "%s_%s" % [name_value, detail_id]
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	detail.mesh = sphere
	detail.position = position_value
	detail.set_meta("camo_detail", true)
	return detail

func _add_shoulders(root: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var shoulder := _sphere_detail("Shoulder", Vector3(side * 0.42, 1.42, 0), 0.19, "L" if side < 0.0 else "R")
		shoulder.scale = Vector3(1.0, 0.72, 0.84)
		shoulder.material_override = _material(Color(0.08, 0.46, 0.48), 0.05, 0.48)
		root.add_child(shoulder)

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
