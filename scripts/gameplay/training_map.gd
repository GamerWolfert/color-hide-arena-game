extends Node3D

func _ready() -> void:
	_build_large_training_map()

func get_hide_spots() -> Array:
	return get_tree().get_nodes_in_group("hide_spots")

func get_patrol_points() -> Array:
	return get_tree().get_nodes_in_group("patrol_points")

func get_spawn_points() -> Array:
	return get_tree().get_nodes_in_group("training_spawns")

func _build_large_training_map() -> void:
	_make_box("BaseFloor", Vector3(0, -0.2, 0), Vector3(58, 0.4, 42), Color(0.15, 0.18, 0.20))
	_make_navigation_surface()
	_make_zone("Garage", Vector3(-18, 0, -10), Vector3(16, 4, 14), Color(0.22, 0.42, 0.50))
	_make_zone("Warehouse", Vector3(8, 0, -9), Vector3(20, 5, 16), Color(0.58, 0.26, 0.50))
	_make_zone("Office", Vector3(-17, 0, 11), Vector3(15, 4, 12), Color(0.32, 0.62, 0.36))
	_make_zone("Garden", Vector3(14, 0, 12), Vector3(20, 3, 14), Color(0.20, 0.55, 0.32))
	_make_zone("Storage", Vector3(23, 0, -4), Vector3(10, 4, 9), Color(0.68, 0.40, 0.22))
	_make_zone("Workshop", Vector3(-5, 0, 10), Vector3(10, 4, 8), Color(0.28, 0.48, 0.68))
	_make_zone("Kitchen", Vector3(2, 0, 15), Vector3(8, 3, 6), Color(0.72, 0.74, 0.78))
	_make_corridor("MainCorridor", Vector3(-2, 1.6, 2), Vector3(42, 3.2, 3), Color(0.92, 0.70, 0.22))
	_make_corridor("NorthHall", Vector3(-2, 1.6, -18), Vector3(48, 3.2, 3), Color(0.26, 0.58, 0.92))
	_make_corridor("VentilationRun", Vector3(18, 1.6, 3), Vector3(3, 3.2, 16), Color(0.70, 0.34, 0.80))

	for x in [-24, -12, 0, 12, 24]:
		_make_box("OuterNorth%d" % x, Vector3(x, 2, -21), Vector3(10, 4, 0.5), Color(0.90, 0.26, 0.24))
		_make_box("OuterSouth%d" % x, Vector3(x, 2, 21), Vector3(10, 4, 0.5), Color(0.20, 0.70, 0.82))
	_make_box("OuterWest", Vector3(-29, 2, 0), Vector3(0.5, 4, 42), Color(0.76, 0.24, 0.72))
	_make_box("OuterEast", Vector3(29, 2, 0), Vector3(0.5, 4, 42), Color(0.92, 0.78, 0.24))

	_make_props()
	_make_height_features()
	_make_markers()

func _make_navigation_surface() -> void:
	var region := NavigationRegion3D.new()
	region.name = "TrainingNavigationRegion"
	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.vertices = PackedVector3Array([
		Vector3(-27.5, 0.02, -19.5),
		Vector3(27.5, 0.02, -19.5),
		Vector3(27.5, 0.02, 19.5),
		Vector3(-27.5, 0.02, 19.5)
	])
	navigation_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	region.navigation_mesh = navigation_mesh
	add_child(region)

func _make_zone(zone_name: String, center: Vector3, size: Vector3, color: Color) -> void:
	_make_box("%sFloor" % zone_name, center + Vector3(0, 0.02, 0), Vector3(size.x, 0.18, size.z), color.darkened(0.35))
	_make_box("%sBackWall" % zone_name, center + Vector3(0, 2, -size.z * 0.5), Vector3(size.x, 4, 0.35), color)
	_make_box("%sSideA" % zone_name, center + Vector3(-size.x * 0.5, 2, 0), Vector3(0.35, 4, size.z), color.lightened(0.12))
	_make_box("%sSideB" % zone_name, center + Vector3(size.x * 0.5, 2, 0), Vector3(0.35, 4, size.z), color.darkened(0.12))

func _make_corridor(name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	_make_box("%sFloor" % name, Vector3(pos.x, 0.0, pos.z), Vector3(size.x, 0.18, size.z), color.darkened(0.45))
	_make_box("%sStripeA" % name, pos + Vector3(0, 0.8, -size.z * 0.45), Vector3(size.x, 1.6, 0.18), color)
	_make_box("%sStripeB" % name, pos + Vector3(0, 1.7, size.z * 0.45), Vector3(size.x, 1.4, 0.18), color.lightened(0.18))

func _make_props() -> void:
	for i in range(7):
		_make_box("WarehouseCrate%d" % i, Vector3(1 + i * 2.3, 0.7, -12 + (i % 3) * 3.0), Vector3(1.6, 1.4, 1.6), Color(0.44, 0.30, 0.18))
	for i in range(5):
		_make_box("GarageCabinet%d" % i, Vector3(-24 + i * 2.4, 1.4, -15), Vector3(1.4, 2.8, 0.8), Color(0.18, 0.50, 0.64))
	_make_box("GarageDoor", Vector3(-18, 1.8, -3), Vector3(5.8, 3.6, 0.28), Color(0.86, 0.38, 0.24))
	for i in range(4):
		_make_box("OfficeTable%d" % i, Vector3(-22 + i * 3.6, 0.8, 10), Vector3(2.4, 0.35, 1.5), Color(0.38, 0.24, 0.16))
		_make_box("OfficeLegs%d" % i, Vector3(-22 + i * 3.6, 0.38, 10), Vector3(2.1, 0.7, 1.2), Color(0.18, 0.16, 0.14))
	for i in range(8):
		_make_box("GardenPlanter%d" % i, Vector3(8 + (i % 4) * 4.2, 0.55, 8 + int(i / 4) * 5.0), Vector3(2.4, 1.1, 1.2), Color(0.18, 0.62, 0.28))
	for i in range(6):
		_make_pipe("Pipe%d" % i, Vector3(-6 + i * 4.0, 2.7, -18), Vector3(3.4, 0.28, 0.28), Color(0.72, 0.74, 0.70))
	for i in range(5):
		_make_box("DoorPanel%d" % i, Vector3(-24 + i * 12, 1.5, 2.1), Vector3(1.6, 3.0, 0.22), Color(0.20, 0.16, 0.10))
	for i in range(4):
		_make_box("StorageRack%d" % i, Vector3(20 + (i % 2) * 4.0, 1.3, -7 + int(i / 2) * 5.0), Vector3(2.8, 2.6, 0.55), Color(0.38, 0.24, 0.18))
	for i in range(3):
		_make_box("WorkshopBench%d" % i, Vector3(-8 + i * 3.0, 0.8, 8.4), Vector3(2.4, 0.35, 1.1), Color(0.20, 0.30, 0.36))
	for i in range(3):
		_make_box("KitchenCounter%d" % i, Vector3(-1.5 + i * 2.0, 0.85, 13.2), Vector3(1.7, 1.4, 0.6), Color(0.76, 0.78, 0.82))

func _make_height_features() -> void:
	_make_box("WarehouseMezzanine", Vector3(14, 2.0, -13), Vector3(9, 0.4, 5), Color(0.26, 0.28, 0.32))
	_make_box("MezzanineRamp", Vector3(8, 1.0, -15), Vector3(5, 0.35, 2.3), Color(0.30, 0.34, 0.36))
	_make_box("GardenPlatform", Vector3(20, 1.0, 16), Vector3(6, 2, 4), Color(0.30, 0.48, 0.22))
	_make_box("OfficeRaisedFloor", Vector3(-18, 0.45, 15), Vector3(10, 0.9, 4), Color(0.22, 0.38, 0.28))

func _make_markers() -> void:
	var hide_data := [
		[Vector3(-24, 1.0, -15.8), Color(0.18, 0.50, 0.64), "Plat tegen muur", 94.0],
		[Vector3(8, 1.0, -12.5), Color(0.44, 0.30, 0.18), "Hurken", 88.0],
		[Vector3(-19, 1.0, 10.4), Color(0.38, 0.24, 0.16), "Armen omhoog", 84.0],
		[Vector3(16, 1.0, 9.2), Color(0.18, 0.62, 0.28), "Leunen", 90.0],
		[Vector3(20, 2.1, 16), Color(0.30, 0.48, 0.22), "Plat tegen muur", 92.0],
		[Vector3(14, 2.4, -13), Color(0.26, 0.28, 0.32), "Hurken", 86.0]
	]
	for i in range(hide_data.size()):
		var marker := Marker3D.new()
		marker.name = "HideSpot%d" % i
		marker.position = hide_data[i][0]
		marker.set_meta("surface_color", hide_data[i][1])
		marker.set_meta("pose", hide_data[i][2])
		marker.set_meta("camouflage", hide_data[i][3])
		marker.add_to_group("hide_spots")
		add_child(marker)
	var patrols := [Vector3(-24, 1.0, -17), Vector3(-6, 1.0, -18), Vector3(12, 1.0, -14), Vector3(23, 1.0, 12), Vector3(0, 1.0, 2), Vector3(-22, 1.0, 12)]
	for i in range(patrols.size()):
		var marker := Marker3D.new()
		marker.name = "Patrol%d" % i
		marker.position = patrols[i]
		marker.add_to_group("patrol_points")
		add_child(marker)
	for i in range(5):
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % i
		marker.position = Vector3(-4 + i * 2.0, 1.2, 18)
		marker.add_to_group("training_spawns")
		add_child(marker)

func _make_box(name: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.set_meta("surface_color", color)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body

func _make_pipe(name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := _make_box(name, pos, size, color)
	body.rotation.z = deg_to_rad(90)
