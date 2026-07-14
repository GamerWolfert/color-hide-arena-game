extends SceneTree

const CHARACTER_SCENE := preload("res://scenes/characters/meccha_character.tscn")
const OUTPUT_DIR := "res://artifacts/visual_validation"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var world := Node3D.new()
	root.add_child(world)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.055, 0.10)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.76, 0.82, 0.92)
	environment.ambient_light_energy = 0.65
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)
	var character: Node3D = CHARACTER_SCENE.instantiate()
	world.add_child(character)
	character.apply_color(Color(0.94, 0.91, 0.82))
	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 1.45
	floor_mesh.bottom_radius = 1.55
	floor_mesh.height = 0.18
	floor.mesh = floor_mesh
	floor.position.y = -0.12
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.08, 0.16, 0.22)
	floor_material.metallic = 0.5
	floor_material.roughness = 0.42
	floor.material_override = floor_material
	world.add_child(floor)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -28, 0)
	light.light_energy = 0.85
	light.shadow_enabled = true
	world.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.2, 2.8, 2.8)
	fill.light_energy = 1.0
	fill.omni_range = 8.0
	world.add_child(fill)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.25, 5.0)
	camera.fov = 42.0
	camera.look_at_from_position(camera.position, Vector3(0, 1.05, 0))
	world.add_child(camera)
	camera.current = true
	await _frames(8)
	_capture("02_character_front.png")
	camera.position.z = -5.0
	camera.look_at_from_position(camera.position, Vector3(0, 1.05, 0))
	await _frames(5)
	_capture("02_character_back.png")
	Input.set_custom_mouse_cursor(null)
	world.queue_free()
	await _frames(2)
	quit()

func _capture(file_name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Character screenshot opslaan mislukt: %s" % path)
	else:
		print("CHARACTER_CAPTURE saved=%s" % path)

func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
