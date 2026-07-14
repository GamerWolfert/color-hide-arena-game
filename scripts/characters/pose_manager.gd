extends Node

signal pose_changed(index: int, pose_name: String)

const POSE_NAMES := [
    "Normaal staan",
    "Zwaaien",
    "Armen omhoog",
    "Hurken",
    "Zitten",
    "Plat op de rug",
    "Plat op de buik",
    "Voorover buigen",
    "Leunen",
    "Smalle stand"
]

var pose_index := 0
var body_parts: Dictionary = {}

func setup(parts: Dictionary) -> void:
    body_parts = parts
    apply_pose()

func get_pose_name() -> String:
    return POSE_NAMES[pose_index]

func set_pose(index: int) -> void:
    pose_index = posmod(index, POSE_NAMES.size())
    apply_pose()
    pose_changed.emit(pose_index, get_pose_name())

func set_pose_by_name(pose_name: String) -> void:
    var index := POSE_NAMES.find(pose_name)
    if index == -1:
        index = 0
    set_pose(index)

func next_pose() -> void:
    set_pose(pose_index + 1)

func previous_pose() -> void:
    set_pose(pose_index - 1)

func apply_pose() -> void:
    if body_parts.is_empty():
        return
    var torso: Node3D = body_parts.get("Torso")
    var head: Node3D = body_parts.get("Head")
    var left_arm: Node3D = body_parts.get("LeftArm")
    var right_arm: Node3D = body_parts.get("RightArm")
    var left_leg: Node3D = body_parts.get("LeftLeg")
    var right_leg: Node3D = body_parts.get("RightLeg")
    if not torso or not head or not left_arm or not right_arm or not left_leg or not right_leg:
        return
    var defaults := {
        "Torso": [Vector3(0, 1.05, 0), Vector3.ONE],
        "Head": [Vector3(0, 1.70, 0), Vector3.ONE],
        "LeftArm": [Vector3(-0.55, 1.10, 0), Vector3.ONE],
        "RightArm": [Vector3(0.55, 1.10, 0), Vector3.ONE],
        "LeftLeg": [Vector3(-0.22, 0.42, 0), Vector3.ONE],
        "RightLeg": [Vector3(0.22, 0.42, 0), Vector3.ONE]
    }
    for part_name in defaults:
        var part: Node3D = body_parts.get(part_name)
        part.position = defaults[part_name][0]
        part.rotation = Vector3.ZERO
        part.scale = defaults[part_name][1]
    match pose_index:
        1:
            left_arm.rotation.z = deg_to_rad(-48.0)
            left_arm.rotation.x = deg_to_rad(-8.0)
            right_arm.position.y = 1.34
            left_arm.position.y = 1.34
        2:
            left_arm.rotation.z = deg_to_rad(-38.0)
            right_arm.rotation.z = deg_to_rad(38.0)
            left_arm.position.y = 1.48
            right_arm.position.y = 1.48
        3:
            torso.scale.y = 0.78
            head.position.y = 1.45
            left_leg.position.y = 0.32
            right_leg.position.y = 0.32
        4:
            torso.rotation.x = deg_to_rad(-18.0)
            torso.position.y = 0.92
            head.position = Vector3(0, 1.44, 0.24)
            left_leg.rotation.x = deg_to_rad(72.0)
            right_leg.rotation.x = deg_to_rad(72.0)
        5:
            torso.rotation.x = deg_to_rad(82.0)
            torso.position.y = 0.56
            head.position = Vector3(0, 0.9, -0.28)
            left_arm.position = Vector3(-0.55, 0.78, -0.12)
            right_arm.position = Vector3(0.55, 0.78, -0.12)
        6:
            torso.rotation.x = deg_to_rad(-82.0)
            torso.position.y = 0.56
            head.position = Vector3(0, 0.9, 0.28)
            left_arm.position = Vector3(-0.55, 0.78, 0.12)
            right_arm.position = Vector3(0.55, 0.78, 0.12)
        7:
            torso.rotation.x = deg_to_rad(-28.0)
            torso.position.y = 1.0
            head.position = Vector3(0, 1.57, 0.18)
            left_arm.rotation.x = deg_to_rad(-18.0)
            right_arm.rotation.x = deg_to_rad(-18.0)
        8:
            torso.rotation.z = deg_to_rad(13.0)
            head.rotation.z = deg_to_rad(13.0)
            left_arm.rotation.z = deg_to_rad(8.0)
            right_arm.rotation.z = deg_to_rad(8.0)
        9:
            left_leg.position.x = -0.14
            right_leg.position.x = 0.14
            left_leg.scale.x = 0.82
            right_leg.scale.x = 0.82

