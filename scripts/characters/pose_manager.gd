extends Node

signal pose_changed(index: int, pose_name: String)

const POSE_NAMES := [
	"Normaal staan",
	"Zitten",
	"Op rug liggen",
	"Op buik liggen",
	"Armen omhoog",
	"Hurken",
	"Leunen",
	"Zwaaien",
	"Plat tegen muur"
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
	set_pose(index if index >= 0 else 0)

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
		"Torso": [Vector3(0, 1.04, 0), Vector3(1.0, 1.0, 0.795)],
		"Head": [Vector3(0, 1.76, -0.015), Vector3(1.0, 1.0, 0.96)],
		"LeftArm": [Vector3(-0.38, 1.04, 0), Vector3(1.0, 1.0, 1.027)],
		"RightArm": [Vector3(0.38, 1.04, 0), Vector3(1.0, 1.0, 1.027)],
		"LeftLeg": [Vector3(-0.18, 0.42, -0.01), Vector3(1.0, 1.0, 1.15)],
		"RightLeg": [Vector3(0.18, 0.42, -0.01), Vector3(1.0, 1.0, 1.15)]
	}
	for part_name in defaults:
		var part: Node3D = body_parts.get(part_name)
		part.position = defaults[part_name][0]
		part.rotation = Vector3.ZERO
		part.scale = defaults[part_name][1]
	match pose_index:
		1:
			_apply_sitting(torso, head, left_arm, right_arm, left_leg, right_leg)
		2:
			_apply_lying(torso, head, left_arm, right_arm, left_leg, right_leg, false)
		3:
			_apply_lying(torso, head, left_arm, right_arm, left_leg, right_leg, true)
		4:
			left_arm.rotation.z = deg_to_rad(-54.0)
			right_arm.rotation.z = deg_to_rad(54.0)
			left_arm.position.y = 1.48
			right_arm.position.y = 1.48
		5:
			torso.scale.y = 0.78
			head.position.y = 1.46
			left_arm.position.y = 0.98
			right_arm.position.y = 0.98
			left_leg.rotation.x = deg_to_rad(-18.0)
			right_leg.rotation.x = deg_to_rad(18.0)
		6:
			torso.rotation.z = deg_to_rad(13.0)
			head.rotation.z = deg_to_rad(13.0)
			left_arm.rotation.z = deg_to_rad(10.0)
			right_arm.rotation.z = deg_to_rad(4.0)
			left_leg.rotation.z = deg_to_rad(-8.0)
		7:
			left_arm.rotation.z = deg_to_rad(-20.0)
			right_arm.rotation.z = deg_to_rad(-8.0)
			left_arm.rotation.x = deg_to_rad(-14.0)
			right_arm.rotation.x = deg_to_rad(-14.0)
		8:
			torso.rotation.x = deg_to_rad(-72.0)
			torso.position = Vector3(0, 0.88, -0.12)
			head.position = Vector3(0, 1.02, -0.42)
			left_arm.position = Vector3(-0.46, 0.98, -0.16)
			right_arm.position = Vector3(0.46, 0.98, -0.16)

func _apply_sitting(torso: Node3D, head: Node3D, left_arm: Node3D, right_arm: Node3D, left_leg: Node3D, right_leg: Node3D) -> void:
	torso.rotation.x = deg_to_rad(-22.0)
	torso.position.y = 0.92
	head.position = Vector3(0, 1.43, 0.20)
	left_leg.rotation.x = deg_to_rad(62.0)
	right_leg.rotation.x = deg_to_rad(62.0)
	left_leg.position.y = 0.30
	right_leg.position.y = 0.30

func _apply_lying(torso: Node3D, head: Node3D, left_arm: Node3D, right_arm: Node3D, left_leg: Node3D, right_leg: Node3D, face_down: bool) -> void:
	torso.rotation.x = deg_to_rad(82.0 if not face_down else -82.0)
	torso.position.y = 0.56
	head.position = Vector3(0, 0.90, 0.28 if not face_down else -0.28)
	left_arm.position = Vector3(-0.52, 0.78, 0.12 if not face_down else -0.12)
	right_arm.position = Vector3(0.52, 0.78, 0.12 if not face_down else -0.12)
	left_leg.position.y = 0.18
	right_leg.position.y = 0.18
