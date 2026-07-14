extends "res://scripts/gameplay/training_map.gd"

func _build_large_training_map() -> void:
	_make_box("CandyFloor", Vector3(0, -0.2, 0), Vector3(52, 0.4, 38), Color(0.08, 0.12, 0.20))
	_make_navigation_surface()
	_make_zone("FrostingGarage", Vector3(-17, 0, -9), Vector3(14, 4, 12), Color(0.10, 0.68, 0.74))
	_make_zone("ChocolateWarehouse", Vector3(8, 0, -10), Vector3(19, 5, 14), Color(0.54, 0.22, 0.42))
	_make_zone("CookieOffice", Vector3(-17, 0, 10), Vector3(14, 4, 11), Color(0.82, 0.35, 0.20))
	_make_zone("CandyGarden", Vector3(14, 0, 10), Vector3(18, 3, 12), Color(0.18, 0.72, 0.38))
	_make_zone("SugarKitchen", Vector3(2, 0, 14), Vector3(8, 3, 6), Color(0.78, 0.30, 0.58))
	_make_corridor("IcingBridge", Vector3(-2, 1.5, 1), Vector3(40, 3.0, 3), Color(0.96, 0.68, 0.18))
	_make_corridor("BlueHall", Vector3(-2, 1.5, -17), Vector3(46, 3.0, 3), Color(0.16, 0.56, 0.94))
	_make_box("NorthCookieWall", Vector3(0, 2.2, -19), Vector3(50, 4.4, 0.5), Color(0.46, 0.20, 0.16))
	_make_box("SouthFrostingWall", Vector3(0, 2.2, 19), Vector3(50, 4.4, 0.5), Color(0.22, 0.54, 0.70))
	_make_box("WestCandyWall", Vector3(-26, 2.2, 0), Vector3(0.5, 4.4, 38), Color(0.78, 0.25, 0.48))
	_make_box("EastCandyWall", Vector3(26, 2.2, 0), Vector3(0.5, 4.4, 38), Color(0.92, 0.72, 0.18))
	_make_props()
	_make_height_features()
	_make_markers()
	_make_lights()

func _make_props() -> void:
	for i in range(6):
		var x := -23.0 + i * 2.3
		_make_box("CookieCrate%d" % i, Vector3(x, 0.75, -13.0), Vector3(1.7, 1.5, 1.7), Color(0.62, 0.32, 0.16))
		_make_neon_strip("CookieIcing%d" % i, Vector3(x, 1.54, -12.12), Vector3(1.2, 0.06, 0.05), Color(1.0, 0.74, 0.30))
	for i in range(5):
		var x := -22.0 + i * 3.2
		_make_box("KitchenTable%d" % i, Vector3(x, 0.72, 8.8), Vector3(2.2, 0.35, 1.5), Color(0.42, 0.20, 0.14))
		_make_box("KitchenLeg%d" % i, Vector3(x, 0.38, 8.8), Vector3(1.7, 0.65, 1.0), Color(0.25, 0.12, 0.12))
	for i in range(4):
		_make_lollipop("Lollipop%d" % i, Vector3(8.0 + i * 3.4, 1.1, 8.0 + (i % 2) * 3.2), [Color(0.96, 0.16, 0.38), Color(0.12, 0.76, 0.86), Color(0.98, 0.72, 0.18), Color(0.68, 0.28, 0.92)][i])
	for i in range(5):
		_make_pipe("ChocolatePipe%d" % i, Vector3(-3.5 + i * 3.5, 2.5, -16.4), Vector3(3.0, 0.32, 0.32), Color(0.28, 0.10, 0.08))
	_make_box("CakePlateau", Vector3(13, 1.1, -2.5), Vector3(7, 2.2, 5), Color(0.92, 0.30, 0.48))
	_make_neon_strip("CakeIcing", Vector3(13, 2.22, -4.95), Vector3(6.3, 0.12, 0.08), Color(1.0, 0.78, 0.34))
	for i in range(4):
		_make_cookie_tree(Vector3(-8.0 + i * 5.0, 0, 12.0 + (i % 2) * 2.0), Color(0.30, 0.78, 0.38))
	_make_sign("CandySign", Vector3(-1.0, 3.4, -18.55), "CANDY WORKSHOP", Color(0.20, 0.95, 0.82))

func _make_height_features() -> void:
	_make_box("FrostingPlatform", Vector3(-1, 2.0, -6), Vector3(8, 0.4, 4), Color(0.16, 0.36, 0.74))
	_make_box("PlatformRamp", Vector3(-5, 1.0, -6), Vector3(6, 0.35, 2.0), Color(0.28, 0.52, 0.82))
	_make_box("GardenCakeTier", Vector3(17, 1.0, 14), Vector3(5, 2.0, 4), Color(0.96, 0.50, 0.18))
	_make_neon_strip("PlatformEdge", Vector3(-1, 2.24, -8.0), Vector3(7.5, 0.06, 0.05), Color(0.18, 0.94, 0.86))

func _make_markers() -> void:
	var hide_data := [
		[Vector3(-21, 1.0, -14.0), Color(0.62, 0.32, 0.16), "Plat tegen muur", 92.0],
		[Vector3(8, 1.0, -13.0), Color(0.54, 0.22, 0.42), "Hurken", 88.0],
		[Vector3(-18, 1.0, 8.0), Color(0.82, 0.35, 0.20), "Armen omhoog", 84.0],
		[Vector3(12, 1.0, 8.5), Color(0.18, 0.72, 0.38), "Leunen", 90.0],
		[Vector3(13, 2.2, -2.5), Color(0.92, 0.30, 0.48), "Plat tegen muur", 91.0],
		[Vector3(-1, 2.6, -6), Color(0.16, 0.36, 0.74), "Zitten", 86.0]
	]
	for i in range(hide_data.size()):
		var marker := Marker3D.new()
		marker.name = "CandyHideSpot%d" % i
		marker.position = hide_data[i][0]
		marker.set_meta("surface_color", hide_data[i][1])
		marker.set_meta("pose", hide_data[i][2])
		marker.set_meta("camouflage", hide_data[i][3])
		marker.add_to_group("hide_spots")
		add_child(marker)
	var patrols := [Vector3(-22, 1.0, -16), Vector3(-7, 1.0, -17), Vector3(10, 1.0, -15), Vector3(22, 1.0, 10), Vector3(0, 1.0, 2), Vector3(-22, 1.0, 11)]
	for i in range(patrols.size()):
		var marker := Marker3D.new()
		marker.name = "CandyPatrol%d" % i
		marker.position = patrols[i]
		marker.add_to_group("patrol_points")
		add_child(marker)
	for i in range(5):
		var marker := Marker3D.new()
		marker.name = "CandySpawn%d" % i
		marker.position = Vector3(-4 + i * 2.0, 1.2, 16)
		marker.add_to_group("training_spawns")
		add_child(marker)

func _make_lollipop(name_value: String, position_value: Vector3, color: Color) -> void:
	var stem := _make_box("%sStem" % name_value, position_value + Vector3(0, 1.4, 0), Vector3(0.16, 2.8, 0.16), Color(0.94, 0.92, 0.84))
	var candy := MeshInstance3D.new()
	candy.name = "%sCandy" % name_value
	var sphere := SphereMesh.new()
	sphere.radius = 0.62
	sphere.height = 1.24
	candy.mesh = sphere
	candy.position = position_value + Vector3(0, 3.0, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.45
	candy.material_override = material
	add_child(candy)

func _make_cookie_tree(position_value: Vector3, color: Color) -> void:
	_make_cylinder_visual("CookieTreeTrunk", position_value + Vector3(0, 0.9, 0), 0.28, 1.8, Color(0.34, 0.16, 0.10))
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	crown.mesh = sphere
	crown.position = position_value + Vector3(0, 2.2, 0)
	crown.material_override = _visual_material(color, 0.0, 0.62)
	add_child(crown)

func _make_cylinder_visual(name_value: String, position_value: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = name_value
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.position = position_value
	mesh.material_override = _visual_material(color, 0.0, 0.72)
	add_child(mesh)

func _make_sign(name_value: String, position_value: Vector3, text_value: String, color: Color) -> void:
	var label := Label3D.new()
	label.name = name_value
	label.text = text_value
	label.position = position_value
	label.font_size = 52
	label.pixel_size = 0.008
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color(0.02, 0.03, 0.08)
	add_child(label)

func _make_lights() -> void:
	_add_light("CandyCyanLight", Vector3(-17, 3.2, -9), Color(0.10, 0.88, 0.96), 3.8, 9.0)
	_add_light("CandyPinkLight", Vector3(8, 4.0, -10), Color(0.90, 0.18, 0.54), 4.0, 10.0)
	_add_light("CandyGardenLight", Vector3(14, 2.5, 10), Color(0.20, 0.92, 0.48), 3.2, 9.0)

func _visual_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material
