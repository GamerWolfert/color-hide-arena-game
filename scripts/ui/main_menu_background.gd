extends Node3D

var _elapsed := 0.0
var _pose_elapsed := 0.0
var _pose_index := 0
var _character: Node3D
var _left_arm: MeshInstance3D
var _right_arm: MeshInstance3D
var _camera: Camera3D
var _key_light: SpotLight3D

func _ready() -> void:
    _create_environment()
    _create_room()
    _create_wall_logo()
    _create_props()
    _create_character()
    _create_lights()
    _create_camera()

func _process(delta: float) -> void:
    _elapsed += delta
    _pose_elapsed += delta
    if _pose_elapsed >= 14.0:
        _pose_elapsed = 0.0
        _pose_index = (_pose_index + 1) % 3
    _animate_character()
    _animate_camera()
    if _key_light:
        _key_light.light_energy = 3.0 + sin(_elapsed * 0.7) * 0.18

func _create_environment() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.008, 0.012, 0.026)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.20, 0.28, 0.46)
    environment.ambient_light_energy = 0.55
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.12, 0.16, 0.28)
    environment.fog_density = 0.012
    var world_environment := WorldEnvironment.new()
    world_environment.environment = environment
    add_child(world_environment)

func _create_room() -> void:
    _box("Floor", Vector3(22.0, 0.16, 16.0), Vector3(0.0, -0.08, -1.2), _material(Color(0.025, 0.045, 0.075), 0.72, 0.24))
    _box("ConcreteWall", Vector3(20.0, 8.0, 0.40), Vector3(0.0, 4.0, -6.2), _material(Color(0.11, 0.10, 0.13), 0.30, 0.82))
    _box("LeftWall", Vector3(0.40, 8.0, 13.0), Vector3(-10.0, 4.0, -0.2), _material(Color(0.035, 0.05, 0.085), 0.20, 0.86))
    _create_brick_sections()
    _box("CeilingBeamA", Vector3(20.0, 0.28, 0.32), Vector3(0.0, 7.4, -3.0), _material(Color(0.07, 0.09, 0.13), 0.75, 0.38))
    _box("CeilingBeamB", Vector3(0.32, 0.28, 12.0), Vector3(2.7, 7.4, -0.6), _material(Color(0.07, 0.09, 0.13), 0.75, 0.38))

func _create_brick_sections() -> void:
    var brick_colors := [Color(0.22, 0.075, 0.075), Color(0.17, 0.055, 0.07), Color(0.24, 0.09, 0.075)]
    for row in range(9):
        var offset: float = 0.0 if row % 2 == 0 else 0.54
        for column in range(15):
            var color: Color = brick_colors[(row + column) % brick_colors.size()]
            var position := Vector3(-7.55 + column * 1.08 + offset, 0.55 + row * 0.47, -6.0)
            _box("Brick_%d_%d" % [row, column], Vector3(1.0, 0.38, 0.10), position, _material(color, 0.05, 0.92))

func _create_wall_logo() -> void:
    var plaque_material := _material(Color(0.028, 0.05, 0.085), 0.45, 0.34)
    _box("LogoPlaque", Vector3(5.3, 2.3, 0.16), Vector3(-2.1, 4.85, -5.75), plaque_material)
    var top := Label3D.new()
    top.name = "MecchaWallLogo"
    top.text = "MECCHA"
    top.font_size = 82
    top.outline_size = 8
    top.modulate = Color(0.18, 0.94, 0.82)
    top.outline_modulate = Color(0.02, 0.04, 0.08)
    top.position = Vector3(-4.25, 5.18, -5.61)
    top.pixel_size = 0.008
    add_child(top)
    var bottom := Label3D.new()
    bottom.name = "ChameleonWallLogo"
    bottom.text = "CHAMELEON"
    bottom.font_size = 55
    bottom.outline_size = 7
    bottom.modulate = Color(0.73, 0.35, 0.96)
    bottom.outline_modulate = Color(0.18, 0.08, 0.28)
    bottom.position = Vector3(-4.25, 4.45, -5.61)
    bottom.pixel_size = 0.008
    add_child(bottom)
    _box("LogoAccent", Vector3(4.75, 0.06, 0.04), Vector3(-1.85, 4.03, -5.56), _material(Color(1.0, 0.73, 0.18), 0.15, 0.30, Color(0.90, 0.48, 0.05)))

func _create_props() -> void:
    var purple := _material(Color(0.41, 0.14, 0.74), 0.24, 0.34, Color(0.19, 0.04, 0.34))
    var turquoise := _material(Color(0.06, 0.58, 0.60), 0.35, 0.30, Color(0.01, 0.20, 0.22))
    var yellow := _material(Color(0.94, 0.60, 0.08), 0.18, 0.40)
    _cylinder("CharacterPlatform", 1.22, 1.10, 0.42, Vector3(3.45, 0.21, -1.35), turquoise)
    _box("PurpleCube", Vector3(1.35, 1.35, 1.35), Vector3(5.55, 0.68, -3.3), purple)
    _box("YellowCube", Vector3(0.94, 0.94, 0.94), Vector3(6.8, 0.47, -4.0), yellow)
    _box("MetalCrate", Vector3(1.75, 1.25, 1.50), Vector3(1.0, 0.62, -4.5), _material(Color(0.13, 0.18, 0.24), 0.82, 0.28))
    _box("CrateStripeA", Vector3(1.82, 0.12, 0.05), Vector3(1.0, 0.80, -3.72), yellow)
    _box("CrateStripeB", Vector3(1.82, 0.12, 0.05), Vector3(1.0, 0.48, -3.72), turquoise)
    _create_ring(Vector3(6.1, 1.55, -2.0), purple)
    _create_camo_object(Vector3(-4.8, 0.0, -3.3), turquoise)

func _create_ring(position: Vector3, material: StandardMaterial3D) -> void:
    var ring := TorusMesh.new()
    ring.inner_radius = 0.72
    ring.outer_radius = 1.08
    var mesh := _mesh_node("PurpleRing", ring, material, position)
    mesh.rotation_degrees = Vector3(0.0, 18.0, 12.0)

func _create_camo_object(position: Vector3, material: StandardMaterial3D) -> void:
    _cylinder("CamoPot", 0.52, 0.43, 0.72, position + Vector3(0.0, 0.36, 0.0), _material(Color(0.12, 0.13, 0.18), 0.52, 0.42))
    for index in range(5):
        var angle := float(index) * TAU / 5.0
        _sphere("CamoLeaf_%d" % index, 0.32, position + Vector3(cos(angle) * 0.34, 1.15 + sin(angle * 2.0) * 0.12, sin(angle) * 0.26), material)

func _create_character() -> void:
    _character = Node3D.new()
    _character.name = "MecchaChameleonCharacter"
    _character.position = Vector3(3.45, 0.42, -1.35)
    add_child(_character)
    var body_material := _material(Color(0.82, 0.88, 0.86), 0.10, 0.58)
    var head_material := _material(Color(0.94, 0.96, 0.92), 0.06, 0.62)
    _character_mesh("Torso", _capsule_mesh(0.38, 1.18), body_material, Vector3(0.0, 1.25, 0.0))
    _character_mesh("Head", _sphere_mesh(0.46), head_material, Vector3(0.0, 2.28, 0.0))
    _left_arm = _character_mesh("LeftArm", _capsule_mesh(0.16, 0.82), body_material, Vector3(-0.53, 1.42, 0.0))
    _right_arm = _character_mesh("RightArm", _capsule_mesh(0.16, 0.82), body_material, Vector3(0.53, 1.42, 0.0))
    _character_mesh("LeftLeg", _capsule_mesh(0.18, 0.88), body_material, Vector3(-0.22, 0.42, 0.0))
    _character_mesh("RightLeg", _capsule_mesh(0.18, 0.88), body_material, Vector3(0.22, 0.42, 0.0))

func _create_lights() -> void:
    _key_light = _spot_light("KeyLight", Vector3(1.8, 5.8, 3.0), Vector3(2.8, 1.1, -1.8), Color(0.20, 0.92, 0.86), 3.0, 18.0)
    _spot_light("PurpleLight", Vector3(7.2, 4.5, 1.2), Vector3(4.0, 1.2, -2.0), Color(0.62, 0.24, 0.95), 2.4, 14.0)
    _spot_light("WarmLight", Vector3(-5.0, 5.2, 1.0), Vector3(-1.5, 1.0, -3.8), Color(1.0, 0.68, 0.24), 1.8, 15.0)
    var fill := OmniLight3D.new()
    fill.name = "FloorFill"
    fill.position = Vector3(0.0, 1.8, 1.0)
    fill.light_color = Color(0.14, 0.24, 0.56)
    fill.light_energy = 1.1
    fill.omni_range = 12.0
    add_child(fill)

func _create_camera() -> void:
    _camera = Camera3D.new()
    _camera.name = "MenuCamera"
    _camera.position = Vector3(0.15, 3.0, 10.0)
    _camera.fov = 58.0
    _camera.current = true
    add_child(_camera)
    _camera.look_at(Vector3(0.8, 1.7, -2.4), Vector3.UP)

func _animate_character() -> void:
    if _character == null or _left_arm == null or _right_arm == null:
        return
    _character.position.y = 0.42 + sin(_elapsed * 1.35) * 0.045
    _character.rotation.y = sin(_elapsed * 0.32) * 0.08
    _left_arm.rotation = Vector3(0.0, 0.0, deg_to_rad(-7.0 + sin(_elapsed * 1.6) * 3.0))
    match _pose_index:
        1:
            _right_arm.rotation = Vector3(0.0, 0.0, deg_to_rad(-42.0 + sin(_elapsed * 2.5) * 16.0))
        2:
            _right_arm.rotation = Vector3(deg_to_rad(18.0), 0.0, deg_to_rad(18.0))
        _:
            _right_arm.rotation = Vector3(0.0, 0.0, deg_to_rad(7.0 + sin(_elapsed * 1.4) * 3.0))

func _animate_camera() -> void:
    if _camera == null:
        return
    _camera.position = Vector3(0.15 + sin(_elapsed * 0.17) * 0.18, 3.0 + sin(_elapsed * 0.23) * 0.06, 10.0 + cos(_elapsed * 0.19) * 0.12)
    _camera.look_at(Vector3(0.8 + sin(_elapsed * 0.15) * 0.14, 1.7, -2.4), Vector3.UP)

func _spot_light(name_value: String, position_value: Vector3, target: Vector3, color: Color, energy: float, light_range: float) -> SpotLight3D:
    var light := SpotLight3D.new()
    light.name = name_value
    light.position = position_value
    light.light_color = color
    light.light_energy = energy
    light.spot_range = light_range
    light.spot_angle = 42.0
    light.shadow_enabled = true
    add_child(light)
    light.look_at(target, Vector3.UP)
    return light

func _character_mesh(name_value: String, mesh: Mesh, material: StandardMaterial3D, position_value: Vector3) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.mesh = mesh
    node.material_override = material
    node.position = position_value
    _character.add_child(node)
    return node

func _box(name_value: String, size_value: Vector3, position_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size_value
    return _mesh_node(name_value, mesh, material, position_value)

func _cylinder(name_value: String, top_radius: float, bottom_radius: float, height: float, position_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = top_radius
    mesh.bottom_radius = bottom_radius
    mesh.height = height
    return _mesh_node(name_value, mesh, material, position_value)

func _sphere(name_value: String, radius: float, position_value: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
    return _mesh_node(name_value, _sphere_mesh(radius), material, position_value)

func _sphere_mesh(radius: float) -> SphereMesh:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    return mesh

func _capsule_mesh(radius: float, height: float) -> CapsuleMesh:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    return mesh

func _mesh_node(name_value: String, mesh: Mesh, material: StandardMaterial3D, position_value: Vector3) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name_value
    node.mesh = mesh
    node.material_override = material
    node.position = position_value
    add_child(node)
    return node

func _material(color: Color, metallic: float = 0.0, roughness: float = 0.60, emission: Color = Color.BLACK) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    if emission != Color.BLACK:
        material.emission_enabled = true
        material.emission = emission
        material.emission_energy_multiplier = 1.1
    return material
