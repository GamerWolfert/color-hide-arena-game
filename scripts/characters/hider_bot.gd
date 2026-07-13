extends CharacterBody3D

signal found(bot: Node)

@export var bot_id := 0

var hidden_alive := true
var camouflage_percent := 0.0
var target_color := Color.WHITE
var pose_name := "Normaal"
var hide_spot: Marker3D
var body_parts := {}

func _ready() -> void:
	add_to_group("hiders")
	_build_body()

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
	_apply_pose(pose_name)
	camouflage_percent = float(hide_spot.get_meta("camouflage", 86.0))

func is_hidden_alive() -> bool:
	return hidden_alive

func mark_found() -> void:
	if not hidden_alive:
		return
	hidden_alive = false
	visible = false
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	found.emit(self)

func get_camouflage_percent() -> float:
	return camouflage_percent if hidden_alive else 0.0

func _build_body() -> void:
	_add_part("Torso", Vector3(0, 1.05, 0), Vector3(0.72, 0.90, 0.34))
	_add_part("Head", Vector3(0, 1.70, 0), Vector3(0.42, 0.42, 0.42))
	_add_part("LeftArm", Vector3(-0.55, 1.10, 0), Vector3(0.22, 0.82, 0.22))
	_add_part("RightArm", Vector3(0.55, 1.10, 0), Vector3(0.22, 0.82, 0.22))
	_add_part("LeftLeg", Vector3(-0.22, 0.42, 0), Vector3(0.26, 0.78, 0.26))
	_add_part("RightLeg", Vector3(0.22, 0.42, 0), Vector3(0.26, 0.78, 0.26))
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
	for part in body_parts.values():
		part.rotation = Vector3.ZERO
	match next_pose:
		"Hurken":
			body_parts["Torso"].scale.y = 0.8
			body_parts["Head"].position.y = 1.48
		"Armen omhoog":
			body_parts["LeftArm"].rotation.z = deg_to_rad(-38)
			body_parts["RightArm"].rotation.z = deg_to_rad(38)
			body_parts["LeftArm"].position.y = 1.45
			body_parts["RightArm"].position.y = 1.45
		"Plat tegen muur":
			for part in body_parts.values():
				part.position.z = -0.22
		_:
			body_parts["Torso"].rotation.z = deg_to_rad(8)

