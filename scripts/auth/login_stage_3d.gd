extends Node3D

func _ready() -> void:
	_build_world()

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.16, 0.30)
	env.ambient_light_energy = 0.6
	world.environment = env
	add_child(world)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 4.3, 12.5)
	camera.rotation_degrees = Vector3(-16, 0, 0)
	camera.fov = 48
	camera.current = true
	add_child(camera)

	_add_light(Vector3(-8, 8, 8), Color(0.12, 0.95, 0.88), 2.4)
	_add_light(Vector3(8, 6, 7), Color(0.72, 0.22, 1.0), 2.0)
	_add_light(Vector3(0, 7, -5), Color(1.0, 0.72, 0.18), 1.3)

	_add_box("Floor", Vector3(0, -0.12, 0), Vector3(22, 0.18, 13), Color(0.025, 0.028, 0.05), 0.55)
	for i in range(-5, 6):
		_add_box("FloorLineX%d" % i, Vector3(i * 2.0, 0.01, 0), Vector3(0.035, 0.03, 13), Color(0.15, 0.12, 0.28), 0.8)
	for j in range(-3, 4):
		_add_box("FloorLineZ%d" % j, Vector3(0, 0.012, j * 2.0), Vector3(22, 0.03, 0.035), Color(0.10, 0.20, 0.25), 0.8)

	_add_left_scene()
	_add_right_scene()
	_add_neon_strips()

func _add_left_scene() -> void:
	_add_box("LeftPurpleBlock", Vector3(-7.4, 0.45, 0.5), Vector3(1.8, 0.9, 1.7), Color(0.44, 0.14, 0.76), 0.65)
	_add_box("LeftTealBlock", Vector3(-5.5, 0.65, -0.2), Vector3(1.7, 1.3, 1.7), Color(0.02, 0.52, 0.50), 0.65)
	_add_cylinder("LeftYellowPlatform", Vector3(-3.8, 0.45, -0.35), 0.9, 0.9, Color(0.92, 0.62, 0.08))
	_add_humanoid("Standing", Vector3(-5.5, 1.52, -0.2), "stand")
	_add_humanoid("Waving", Vector3(-3.8, 1.38, -0.35), "wave")
	_add_humanoid("Sitting", Vector3(-5.1, 0.98, 1.55), "sit")
	_add_sign("LeftSign", Vector3(-7.2, 1.2, 2.1), Vector3(1.7, 1.1, 0.12), "STAY\nHIDDEN.", Color(0.04, 0.17, 0.18))

func _add_right_scene() -> void:
	_add_box("RightTealCube", Vector3(5.4, 0.8, -1.0), Vector3(2.2, 1.6, 1.8), Color(0.02, 0.50, 0.56), 0.62)
	_add_box("RightPurpleSeat", Vector3(5.3, 0.35, 1.4), Vector3(1.7, 0.7, 1.4), Color(0.48, 0.15, 0.78), 0.65)
	_add_box("RightYellowBlock", Vector3(8.2, 0.45, 1.2), Vector3(1.1, 0.9, 1.1), Color(0.92, 0.62, 0.08), 0.65)
	_add_torus_like_ring("PurpleRing", Vector3(7.3, 1.08, -0.1), Color(0.58, 0.15, 0.88))
	_add_humanoid("ArmsUp", Vector3(5.4, 1.95, -1.0), "arms_up")
	_add_humanoid("SittingRight", Vector3(5.4, 1.03, 1.4), "sit")
	_add_humanoid("LyingRight", Vector3(6.4, 0.36, 2.8), "lie")
	_add_humanoid("CrouchRight", Vector3(8.2, 0.85, 2.3), "crouch")
	_add_sign("RightSign", Vector3(8.0, 2.55, -1.7), Vector3(2.1, 1.35, 0.14), "HIDE.\nBLEND.\nWIN.", Color(0.03, 0.14, 0.18))

func _add_neon_strips() -> void:
	_add_box("BackTealStrip", Vector3(-4.5, 0.08, -4.0), Vector3(6.5, 0.06, 0.08), Color(0.0, 0.95, 0.82), 1.0)
	_add_box("BackPurpleStrip", Vector3(5.6, 0.09, -3.7), Vector3(6.5, 0.06, 0.08), Color(0.58, 0.12, 1.0), 1.0)
	_add_box("WallAccentA", Vector3(-8.0, 4.2, -4.0), Vector3(2.2, 0.18, 0.1), Color(0.28, 0.08, 0.58), 0.8).rotation_degrees.z = -38
	_add_box("WallAccentB", Vector3(7.4, 4.0, -4.0), Vector3(2.8, 0.16, 0.1), Color(0.05, 0.35, 0.48), 0.8).rotation_degrees.z = 35

func _add_humanoid(name_prefix: String, base_pos: Vector3, pose: String) -> void:
	var root := Node3D.new()
	root.name = name_prefix
	root.position = base_pos
	add_child(root)
	var white := Color(0.93, 0.88, 0.80)
	var body := _part(root, "Body", Vector3(0, 0.52, 0), Vector3(0.46, 0.82, 0.30), white)
	var head := _sphere(root, "Head", Vector3(0, 1.05, 0), 0.28, white)
	var left_arm := _part(root, "LeftArm", Vector3(-0.35, 0.58, 0), Vector3(0.16, 0.58, 0.16), white)
	var right_arm := _part(root, "RightArm", Vector3(0.35, 0.58, 0), Vector3(0.16, 0.58, 0.16), white)
	var left_leg := _part(root, "LeftLeg", Vector3(-0.14, 0.05, 0), Vector3(0.16, 0.55, 0.16), white)
	var right_leg := _part(root, "RightLeg", Vector3(0.14, 0.05, 0), Vector3(0.16, 0.55, 0.16), white)
	match pose:
		"wave":
			right_arm.rotation_degrees.z = -42
			right_arm.position.y = 0.86
			left_arm.rotation_degrees.z = 12
		"arms_up":
			left_arm.rotation_degrees.z = 42
			right_arm.rotation_degrees.z = -42
			left_arm.position.y = 0.92
			right_arm.position.y = 0.92
		"sit":
			body.rotation_degrees.x = -7
			left_leg.rotation_degrees.x = 72
			right_leg.rotation_degrees.x = 72
			left_leg.position = Vector3(-0.16, -0.04, 0.32)
			right_leg.position = Vector3(0.16, -0.04, 0.32)
		"lie":
			root.rotation_degrees.z = 86
			root.position.y -= 0.16
		"crouch":
			root.scale = Vector3(0.85, 0.70, 0.85)
			left_arm.rotation_degrees.z = 18
			right_arm.rotation_degrees.z = -18
		_:
			left_arm.rotation_degrees.z = 8
			right_arm.rotation_degrees.z = -8
	head.name = "Head"
	body.name = "Body"

func _part(parent: Node3D, part_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.position = pos
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _mat(color, 0.82)
	parent.add_child(mesh)
	return mesh

func _sphere(parent: Node3D, part_name: String, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.position = pos
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.material_override = _mat(color, 0.86)
	parent.add_child(mesh)
	return mesh

func _add_box(name: String, pos: Vector3, size: Vector3, color: Color, roughness := 0.7) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.position = pos
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _mat(color, roughness)
	add_child(mesh)
	return mesh

func _add_cylinder(name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	mesh.position = pos
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.material_override = _mat(color, 0.68)
	add_child(mesh)
	return mesh

func _add_torus_like_ring(name: String, pos: Vector3, color: Color) -> void:
	var outer := _add_cylinder(name, pos, 0.92, 0.34, color)
	outer.rotation_degrees.x = 90
	var inner := _add_cylinder("%sHole" % name, pos + Vector3(0, 0, 0.02), 0.55, 0.38, Color(0.01, 0.012, 0.035))
	inner.rotation_degrees.x = 90

func _add_sign(name: String, pos: Vector3, size: Vector3, text: String, color: Color) -> void:
	var sign := _add_box(name, pos, size, color, 0.72)
	sign.rotation_degrees.y = -8
	var label := Label3D.new()
	label.name = "%sText" % name
	label.text = text
	label.position = pos + Vector3(0, 0, 0.09)
	label.rotation_degrees = sign.rotation_degrees
	label.modulate = Color(0.18, 0.95, 0.82)
	label.font_size = 54
	label.pixel_size = 0.012
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

func _add_light(pos: Vector3, color: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 14
	add_child(light)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.0
	mat.emission_enabled = color.v > 0.75
	mat.emission = color
	mat.emission_energy_multiplier = 0.12 if color.v > 0.75 else 0.0
	return mat
