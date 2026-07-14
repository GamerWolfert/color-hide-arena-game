extends "res://scripts/gameplay/training_map.gd"

const COOKIE := Color(0.56, 0.29, 0.12)
const CHOCOLATE := Color(0.20, 0.055, 0.035)
const FROSTING := Color(1.0, 0.38, 0.66)
const MINT := Color(0.16, 0.86, 0.55)
const CREAM := Color(0.92, 0.72, 0.40)
const CYAN := Color(0.08, 0.76, 0.94)
const YELLOW := Color(1.0, 0.70, 0.08)
const RED := Color(0.94, 0.12, 0.20)
const BLUE := Color(0.12, 0.32, 0.92)
const STEEL := Color(0.62, 0.70, 0.74)

var prop_count := 0

func _create_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.32, 0.76, 0.92)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.58, 0.80, 0.92)
	environment.fog_density = 0.003
	var world_environment := WorldEnvironment.new()
	world_environment.name = "CandyWorkshopEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

func _build_large_training_map() -> void:
	_make_box("BiscuitFoundation", Vector3(0, -0.28, 0), Vector3(52, 0.55, 38), Color(0.42, 0.22, 0.10))
	_build_floor_pattern()
	_build_central_cake()
	_build_frosting_kitchen()
	_build_chocolate_workshop()
	_build_cookie_storage()
	_build_candy_garden()
	_build_packaging_room()
	_build_oven_room()
	_build_bridges_and_heights()
	_build_boundary_scenery()
	_make_navigation_surface()
	_make_markers()
	_make_lights()
	set_meta("candy_prop_count", prop_count)
	set_meta("gameplay_map", "Candy Workshop")

func _build_floor_pattern() -> void:
	for x in range(-6, 7):
		for z in range(-4, 5):
			var tint := Color(0.66, 0.40, 0.19) if (x + z) % 2 == 0 else Color(0.50, 0.28, 0.13)
			_make_decor_box("BiscuitTile_%d_%d" % [x, z], Vector3(x * 4.0, 0.015, z * 4.0), Vector3(3.88, 0.05, 3.88), tint, false)
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		_make_sphere_prop("CandyPebble%d" % index, Vector3(cos(angle) * 19.5, 0.22, sin(angle) * 14.0), 0.26 + 0.08 * (index % 3), [FROSTING, CYAN, YELLOW, MINT, RED][index % 5], true)

func _build_central_cake() -> void:
	_make_cylinder_prop("CentralCakeBase", Vector3(0, 0.42, -3.0), 3.65, 0.76, COOKIE, true)
	_make_cylinder_prop("CentralCreamLayer", Vector3(0, 0.86, -3.0), 3.45, 0.18, CREAM, true)
	_make_cylinder_prop("CentralPinkLayer", Vector3(0, 1.18, -3.0), 2.85, 0.48, FROSTING, true)
	_make_cylinder_prop("CentralTopLayer", Vector3(0, 1.49, -3.0), 2.05, 0.18, CREAM, true)
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		_make_sphere_prop("CakeCandy%d" % index, Vector3(cos(angle) * 1.72, 1.76, -3.0 + sin(angle) * 1.72), 0.20, [RED, YELLOW, CYAN, MINT][index % 4], false)
	_make_sign("CentralCakeSign", Vector3(0, 3.45, -3.0), "CANDY WORKSHOP", CYAN)

func _build_frosting_kitchen() -> void:
	_make_landmark_backdrop("FrostingKitchen", Vector3(-18, 0, -10), Vector3(13, 4.8, 0.45), Color(0.97, 0.48, 0.68))
	for index in range(4):
		var x := -22.5 + index * 3.0
		_make_decor_box("KitchenCounter%d" % index, Vector3(x, 0.72, -8.4), Vector3(2.5, 1.35, 1.4), CREAM, true)
		_make_decor_box("CounterTop%d" % index, Vector3(x, 1.43, -8.4), Vector3(2.75, 0.15, 1.65), STEEL, true, 0.55)
		_make_bowl("MixingBowl%d" % index, Vector3(x, 1.72, -8.4), [FROSTING, MINT, YELLOW, CYAN][index])
		_make_utensil("KitchenSpoon%d" % index, Vector3(x + 0.55, 1.78, -8.15), false)
		_make_utensil("KitchenFork%d" % index, Vector3(x - 0.55, 1.78, -8.15), true)
	for index in range(5):
		_make_cupcake("KitchenCupcake%d" % index, Vector3(-23.0 + index * 2.5, 0.0, -5.8), [FROSTING, MINT, CYAN, YELLOW, RED][index])

func _build_chocolate_workshop() -> void:
	_make_landmark_backdrop("ChocolateWorkshop", Vector3(18, 0, -10), Vector3(14, 5.0, 0.5), CHOCOLATE.lightened(0.12))
	for index in range(5):
		_make_pipe("ChocolatePipe%d" % index, Vector3(12.5 + index * 2.5, 2.8 + (index % 2) * 0.65, -9.6), Vector3(2.1, 0.42, 0.42), CHOCOLATE)
		prop_count += 1
	for index in range(6):
		_make_cookie_block("ChocolateBlock%d" % index, Vector3(13.0 + (index % 3) * 3.0, 0.55, -6.4 + int(index / 3) * 2.0), CHOCOLATE.lightened(0.06 * (index % 2)))
	_make_cylinder_prop("ChocolateVat", Vector3(21.5, 1.15, -5.5), 1.65, 2.3, STEEL.darkened(0.2), true, 0.72)
	_make_cylinder_prop("ChocolateVatFill", Vector3(21.5, 2.31, -5.5), 1.48, 0.10, CHOCOLATE, false)

func _build_cookie_storage() -> void:
	_make_landmark_backdrop("CookieStorage", Vector3(-18, 0, 10.5), Vector3(14, 5.0, 0.5), COOKIE.lightened(0.18))
	for row in range(2):
		for column in range(5):
			_make_cookie_block("CookieCrate%d_%d" % [row, column], Vector3(-23.0 + column * 2.4, 0.65 + row * 1.25, 8.6), COOKIE.lightened(0.05 * row))
	for index in range(4):
		_make_jar("CandyJar%d" % index, Vector3(-22.0 + index * 3.2, 0.0, 13.0), [RED, CYAN, MINT, FROSTING][index])

func _build_candy_garden() -> void:
	for index in range(7):
		var x := 8.5 + (index % 4) * 3.4
		var z := 9.0 + int(index / 4) * 4.2
		_make_lollipop("GardenLollipop%d" % index, Vector3(x, 0.0, z), [FROSTING, CYAN, YELLOW, RED, MINT][index % 5])
	for index in range(5):
		_make_candy_tree("CandyTree%d" % index, Vector3(7.0 + index * 3.7, 0.0, 15.2 - (index % 2) * 1.6), [MINT, CYAN, FROSTING][index % 3])
	for index in range(8):
		_make_marshmallow("Marshmallow%d" % index, Vector3(8.5 + (index % 4) * 2.3, 0.0, 6.0 + int(index / 4) * 1.8), [CREAM, FROSTING, CYAN][index % 3])

func _build_packaging_room() -> void:
	_make_landmark_backdrop("PackagingRoom", Vector3(20, 0, 3.5), Vector3(0.5, 4.5, 9.0), BLUE.lightened(0.15))
	for index in range(8):
		var position := Vector3(16.0 + (index % 3) * 2.3, 0.62, 1.0 + int(index / 3) * 2.1)
		_make_decor_box("GiftBox%d" % index, position, Vector3(1.65, 1.2, 1.65), [RED, YELLOW, CYAN, FROSTING][index % 4], true)
		_make_decor_box("GiftRibbon%d" % index, position + Vector3(0, 0.64, 0), Vector3(0.24, 0.08, 1.72), CREAM, false)

func _build_oven_room() -> void:
	_make_landmark_backdrop("OvenRoom", Vector3(-20, 0, 2.0), Vector3(0.5, 4.8, 9.0), Color(0.78, 0.22, 0.11))
	for index in range(3):
		_make_decor_box("CandyOven%d" % index, Vector3(-17.8, 1.25, -0.8 + index * 2.8), Vector3(2.5, 2.5, 2.2), Color(0.25, 0.20, 0.18), true, 0.75)
		_make_decor_box("OvenGlow%d" % index, Vector3(-16.52, 1.25, -0.8 + index * 2.8), Vector3(0.06, 1.4, 1.45), Color(1.0, 0.28, 0.04), false, 0.25, true)
	for index in range(5):
		_make_decor_box("BakingTray%d" % index, Vector3(-13.5, 0.35 + index * 0.28, -1.2), Vector3(3.4, 0.10, 1.9), STEEL, true, 0.45)

func _build_bridges_and_heights() -> void:
	_make_decor_box("WaferBridge", Vector3(7.2, 1.45, 7.5), Vector3(7.0, 0.32, 2.1), COOKIE.lightened(0.22), true)
	for side in [-1.0, 1.0]:
		_make_pipe("BridgeRail%s" % str(side), Vector3(7.2, 2.1, 7.5 + side * 0.95), Vector3(6.6, 0.16, 0.16), CREAM)
		prop_count += 1
	_make_decor_box("SugarStepA", Vector3(-6.0, 0.35, 7.5), Vector3(2.0, 0.7, 2.0), FROSTING, true)
	_make_decor_box("SugarStepB", Vector3(-7.4, 0.7, 7.5), Vector3(1.2, 1.4, 2.0), CYAN, true)
	_make_cylinder_prop("LookoutCookie", Vector3(10.0, 1.0, 0.0), 3.0, 2.0, COOKIE, true)
	_make_decor_box("WaferRamp", Vector3(7.2, 0.50, 0.0), Vector3(4.0, 0.28, 2.0), CREAM, true)

func _build_boundary_scenery() -> void:
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var position := Vector3(cos(angle) * 25.0, 0.0, sin(angle) * 18.0)
		# Keep the third-person camera's initial sightline clear.
		if position.z > 15.0 and absf(position.x) < 3.0:
			continue
		_make_candy_tree("BoundaryTree%d" % index, position, [FROSTING, CYAN, MINT, YELLOW][index % 4], false)
	_make_decor_box("NorthWaferWall", Vector3(0, 1.2, -18.8), Vector3(44, 2.4, 0.45), COOKIE.lightened(0.12), true)
	_make_decor_box("SouthWaferWall", Vector3(0, 1.2, 18.8), Vector3(44, 2.4, 0.45), COOKIE.lightened(0.08), true)

func _make_markers() -> void:
	var hide_data := [
		[Vector3(-21, 1.0, -8.1), FROSTING, "Leunen", 91.0],
		[Vector3(16, 1.0, -6.2), CHOCOLATE, "Hurken", 94.0],
		[Vector3(-20, 1.0, 12.5), COOKIE, "Armen omhoog", 88.0],
		[Vector3(13, 1.0, 13.0), MINT, "Op buik liggen", 92.0],
		[Vector3(0, 2.3, -3.0), FROSTING, "Zitten", 89.0],
		[Vector3(10, 2.2, 0.0), COOKIE, "Op rug liggen", 90.0]
	]
	for index in range(hide_data.size()):
		var marker := Marker3D.new()
		marker.name = "CandyHideSpot%d" % index
		marker.position = hide_data[index][0]
		marker.set_meta("surface_color", hide_data[index][1])
		marker.set_meta("pose", hide_data[index][2])
		marker.set_meta("camouflage", hide_data[index][3])
		marker.add_to_group("hide_spots")
		add_child(marker)
	var patrols := [Vector3(8, 1, 10), Vector3(15, 1, 7), Vector3(15, 1, -7), Vector3(0, 1, -12), Vector3(-14, 1, -7), Vector3(-15, 1, 7), Vector3(4, 1, 5)]
	for index in range(patrols.size()):
		var marker := Marker3D.new()
		marker.name = "CandyPatrol%d" % index
		marker.position = patrols[index]
		marker.add_to_group("patrol_points")
		add_child(marker)
	for index in range(6):
		var spawn := Marker3D.new()
		spawn.name = "CandySpawn%d" % index
		spawn.position = Vector3(-5.0 + index * 2.0, 1.2, 15.5)
		spawn.add_to_group("training_spawns")
		add_child(spawn)

func _make_lollipop(prop_name: String, base: Vector3, color: Color) -> void:
	_make_cylinder_prop("%sStick" % prop_name, base + Vector3(0, 1.15, 0), 0.10, 2.3, CREAM, true)
	_make_sphere_prop("%sCandy" % prop_name, base + Vector3(0, 2.55, 0), 0.68, color, true, 0.42, true)

func _make_cupcake(prop_name: String, base: Vector3, frosting_color: Color) -> void:
	_make_cylinder_prop("%sWrapper" % prop_name, base + Vector3(0, 0.48, 0), 0.58, 0.88, COOKIE.lightened(0.14), true)
	_make_sphere_prop("%sFrosting" % prop_name, base + Vector3(0, 1.15, 0), 0.62, frosting_color, true)
	_make_sphere_prop("%sCherry" % prop_name, base + Vector3(0, 1.70, 0), 0.18, RED, false, 0.38, true)

func _make_cookie_block(prop_name: String, position: Vector3, color: Color) -> void:
	_make_decor_box(prop_name, position, Vector3(1.75, 1.20, 0.72), color, true)
	for chip in range(4):
		_make_sphere_prop("%sChip%d" % [prop_name, chip], position + Vector3(-0.52 + (chip % 2) * 1.0, 0.28 - int(chip / 2) * 0.55, -0.38), 0.09, CHOCOLATE, false)

func _make_marshmallow(prop_name: String, base: Vector3, color: Color) -> void:
	_make_cylinder_prop(prop_name, base + Vector3(0, 0.38, 0), 0.42, 0.76, color, true)

func _make_jar(prop_name: String, base: Vector3, candy_color: Color) -> void:
	_make_cylinder_prop(prop_name, base + Vector3(0, 0.85, 0), 0.68, 1.55, Color(0.72, 0.90, 1.0, 0.72), true, 0.05)
	_make_cylinder_prop("%sLid" % prop_name, base + Vector3(0, 1.70, 0), 0.72, 0.18, STEEL, false, 0.55)
	for index in range(5):
		_make_sphere_prop("%sCandy%d" % [prop_name, index], base + Vector3(-0.30 + (index % 3) * 0.30, 0.45 + int(index / 3) * 0.42, 0), 0.16, candy_color.lightened(index * 0.04), false)

func _make_bowl(prop_name: String, position: Vector3, filling: Color) -> void:
	_make_cylinder_prop(prop_name, position, 0.68, 0.30, STEEL, true, 0.62)
	_make_sphere_prop("%sMix" % prop_name, position + Vector3(0, 0.20, 0), 0.55, filling, false)

func _make_utensil(prop_name: String, position: Vector3, fork: bool) -> void:
	var root := Node3D.new()
	root.name = prop_name
	root.position = position
	root.rotation_degrees = Vector3(0, 18 if fork else -18, 78 if fork else 102)
	add_child(root)
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.035
	handle_mesh.bottom_radius = 0.045
	handle_mesh.height = 0.92
	handle.mesh = handle_mesh
	handle.material_override = _material(STEEL, 0.32, 0.72)
	root.add_child(handle)
	if fork:
		for tine_index in range(3):
			var tine := MeshInstance3D.new()
			var tine_mesh := BoxMesh.new()
			tine_mesh.size = Vector3(0.025, 0.22, 0.025)
			tine.mesh = tine_mesh
			tine.position = Vector3(-0.055 + tine_index * 0.055, 0.54, 0)
			tine.material_override = _material(STEEL, 0.32, 0.72)
			root.add_child(tine)
	else:
		var spoon := MeshInstance3D.new()
		var spoon_mesh := SphereMesh.new()
		spoon_mesh.radius = 0.13
		spoon_mesh.height = 0.20
		spoon.mesh = spoon_mesh
		spoon.position.y = 0.53
		spoon.scale = Vector3(0.72, 1.0, 0.28)
		spoon.material_override = _material(STEEL, 0.32, 0.72)
		root.add_child(spoon)
	prop_count += 1

func _make_candy_tree(prop_name: String, base: Vector3, color: Color, collision := true) -> void:
	_make_cylinder_prop("%sTrunk" % prop_name, base + Vector3(0, 1.0, 0), 0.28, 2.0, COOKIE.darkened(0.2), collision)
	_make_sphere_prop("%sCrownA" % prop_name, base + Vector3(0, 2.35, 0), 1.05, color, collision)
	_make_sphere_prop("%sCrownB" % prop_name, base + Vector3(0.62, 2.15, 0.15), 0.72, color.lightened(0.08), false)

func _make_landmark_backdrop(prop_name: String, base: Vector3, size: Vector3, color: Color) -> void:
	var wall_color := color.darkened(0.42)
	_make_decor_box("%sWall" % prop_name, base + Vector3(0, size.y * 0.5, 0), size, wall_color, true)
	_make_neon_strip("%sTrim" % prop_name, base + Vector3(0, size.y - 0.35, -size.z * 0.55), Vector3(maxf(size.x - 0.7, 0.1), 0.12, 0.10), color.lightened(0.28))
	if size.x > size.z:
		for panel_index in range(5):
			var panel_x := base.x - size.x * 0.38 + panel_index * size.x * 0.19
			_make_decor_box("%sPanel%d" % [prop_name, panel_index], Vector3(panel_x, 2.25, base.z - size.z * 0.58), Vector3(size.x * 0.15, 2.55, 0.10), color.lightened(0.04 * (panel_index % 2)), false)
	else:
		for panel_index in range(4):
			var panel_z := base.z - size.z * 0.34 + panel_index * size.z * 0.23
			_make_decor_box("%sPanel%d" % [prop_name, panel_index], Vector3(base.x - size.x * 0.58, 2.2, panel_z), Vector3(0.10, 2.45, size.z * 0.16), color.lightened(0.04 * (panel_index % 2)), false)
	prop_count += 1

func _make_decor_box(prop_name: String, position: Vector3, size: Vector3, color: Color, collision: bool, roughness := 0.78, emission := false) -> Node3D:
	var node: Node3D
	if collision:
		node = _make_box(prop_name, position, size, color)
	else:
		var mesh := MeshInstance3D.new()
		mesh.name = prop_name
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
		mesh.position = position
		mesh.material_override = _material(color, roughness, 0.0, emission)
		mesh.set_meta("surface_color", color)
		add_child(mesh)
		node = mesh
	if node is StaticBody3D:
		var visual := node.get_child(0) as MeshInstance3D
		if visual:
			visual.material_override = _material(color, roughness, 0.0, emission)
	prop_count += 1
	return node

func _make_cylinder_prop(prop_name: String, position: Vector3, radius: float, height: float, color: Color, collision: bool, metallic := 0.0) -> Node3D:
	var holder := StaticBody3D.new() if collision else Node3D.new()
	holder.name = prop_name
	holder.position = position
	holder.set_meta("surface_color", color)
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius * 1.04
	cylinder.height = height
	cylinder.radial_segments = 24
	mesh.mesh = cylinder
	mesh.material_override = _material(color, 0.68, metallic)
	holder.add_child(mesh)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		shape_node.shape = shape
		holder.add_child(shape_node)
	add_child(holder)
	prop_count += 1
	return holder

func _make_sphere_prop(prop_name: String, position: Vector3, radius: float, color: Color, collision: bool, roughness := 0.62, emission := false) -> Node3D:
	var holder := StaticBody3D.new() if collision else Node3D.new()
	holder.name = prop_name
	holder.position = position
	holder.set_meta("surface_color", color)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	mesh.mesh = sphere
	mesh.material_override = _material(color, roughness, 0.0, emission)
	holder.add_child(mesh)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = radius
		shape_node.shape = shape
		holder.add_child(shape_node)
	add_child(holder)
	prop_count += 1
	return holder

func _material(color: Color, roughness: float, metallic: float, emission := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = 1.8
	return material

func _make_sign(prop_name: String, position: Vector3, text_value: String, color: Color) -> void:
	var label := Label3D.new()
	label.name = prop_name
	label.text = text_value
	label.position = position
	label.font_size = 72
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 8
	label.outline_modulate = Color(0.12, 0.04, 0.10)
	add_child(label)
	prop_count += 1

func _make_lights() -> void:
	_add_light("CakeKeyLight", Vector3(0, 7.0, -2.0), Color(1.0, 0.76, 0.56), 0.56, 15.0)
	_add_light("KitchenPinkLight", Vector3(-18, 5.0, -7.0), Color(1.0, 0.25, 0.62), 0.40, 12.0)
	_add_light("ChocolateWarmLight", Vector3(17, 5.0, -7.0), Color(1.0, 0.38, 0.12), 0.40, 11.0)
	_add_light("GardenMintLight", Vector3(14, 5.0, 11.0), Color(0.18, 1.0, 0.62), 0.40, 12.0)
	var sun := DirectionalLight3D.new()
	sun.name = "CandySun"
	sun.rotation_degrees = Vector3(-58, -28, 0)
	sun.light_color = Color(1.0, 0.88, 0.74)
	sun.light_energy = 0.34
	sun.shadow_enabled = true
	add_child(sun)
