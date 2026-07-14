extends Node3D

const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")

var body_parts: Dictionary = {}
var pose_manager: Node

func _ready() -> void:
    _build_body()

func set_body_part_color(part_name: String, color: Color, metallic := 0.0, roughness := 0.78) -> void:
    var part: MeshInstance3D = body_parts.get(part_name)
    if not part:
        return
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = clampf(metallic, 0.0, 1.0)
    material.roughness = clampf(roughness, 0.05, 1.0)
    part.material_override = material

func get_body_parts() -> Dictionary:
    return body_parts

func _build_body() -> void:
    pose_manager = PoseManagerScript.new()
    pose_manager.name = "PoseManager"
    add_child(pose_manager)
    _add_part("Torso", Vector3(0, 1.05, 0), 0.38, 1.04)
    _add_part("Head", Vector3(0, 1.76, 0), 0.36, 0.72, true)
    _add_part("LeftArm", Vector3(-0.54, 1.12, 0), 0.14, 0.82)
    _add_part("RightArm", Vector3(0.54, 1.12, 0), 0.14, 0.82)
    _add_part("LeftLeg", Vector3(-0.22, 0.43, 0), 0.17, 0.88)
    _add_part("RightLeg", Vector3(0.22, 0.43, 0), 0.17, 0.88)
    pose_manager.setup(body_parts)

func _add_part(part_name: String, part_position: Vector3, radius: float, height: float, sphere := false) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = part_name
    mesh.position = part_position
    if sphere:
        var sphere_mesh := SphereMesh.new()
        sphere_mesh.radius = radius
        sphere_mesh.height = height
        mesh.mesh = sphere_mesh
    else:
        var capsule := CapsuleMesh.new()
        capsule.radius = radius
        capsule.height = height
        mesh.mesh = capsule
    mesh.set_meta("body_part", part_name)
    body_parts[part_name] = mesh
    add_child(mesh)
    set_body_part_color(part_name, Color(0.82, 0.84, 0.78))
