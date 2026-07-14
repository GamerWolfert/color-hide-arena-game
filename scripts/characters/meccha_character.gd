extends Node3D

const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")
const ANIMATION_NAMES := ["Idle", "Walk", "Run", "Jump", "Crouch", "Sit", "LieBack", "LieFront", "ArmsUp", "Wave", "Lean"]

var body_parts: Dictionary = {}
var pose_manager: Node
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_playback: AnimationNodeStateMachinePlayback
var _body_root: Node3D
var _torso_blends: Array[MeshInstance3D] = []
var _default_color := Color(0.94, 0.91, 0.82)
var _current_animation := ""

func _ready() -> void:
	_build_body()
	pose_manager = PoseManagerScript.new()
	pose_manager.name = "PoseManager"
	add_child(pose_manager)
	pose_manager.setup(body_parts)
	_build_animation_system()
	apply_color(_default_color)
	play_animation("Idle")

func get_body_parts() -> Dictionary:
	return body_parts

func get_pose_manager() -> Node:
	return pose_manager

func apply_color(color: Color) -> void:
	for part_name in body_parts:
		_set_part_material(body_parts[part_name], color)

func set_body_part_style(part_name: String, color: Color, metallic := 0.0, roughness := 0.72) -> void:
	var part: MeshInstance3D = body_parts.get(part_name)
	if part == null:
		return
	part.material_override = _material(color, metallic, roughness)
	if part_name == "Torso":
		for blend in _torso_blends:
			blend.material_override = _material(color, metallic, roughness)

func get_body_part_color(part_name: String) -> Color:
	var part: MeshInstance3D = body_parts.get(part_name)
	if part and part.material_override is StandardMaterial3D:
		return part.material_override.albedo_color
	return _default_color

func play_animation(animation_name: String) -> void:
	if animation_name == _current_animation or not ANIMATION_NAMES.has(animation_name):
		return
	_current_animation = animation_name
	if animation_playback:
		animation_playback.start(animation_name)

func play_pose_animation(index: int) -> void:
	var pose_animations := ["Idle", "Sit", "LieBack", "LieFront", "ArmsUp", "Crouch", "Lean", "Wave"]
	if index >= 0 and index < pose_animations.size():
		play_animation(pose_animations[index])

func _build_body() -> void:
	_body_root = Node3D.new()
	_body_root.name = "BodyParts"
	add_child(_body_root)
	# The ellipsoids overlap deeply, making one soft silhouette without joint balls.
	_add_ellipsoid("Torso", Vector3(0, 1.04, 0), 0.50, Vector3(0.78, 1.14, 0.62))
	_add_ellipsoid("Head", Vector3(0, 1.76, -0.015), 0.43, Vector3(1.0, 1.02, 0.96))
	_add_ellipsoid("LeftArm", Vector3(-0.38, 1.04, 0), 0.22, Vector3(0.74, 2.18, 0.76))
	_add_ellipsoid("RightArm", Vector3(0.38, 1.04, 0), 0.22, Vector3(0.74, 2.18, 0.76))
	_add_ellipsoid("LeftLeg", Vector3(-0.18, 0.42, -0.01), 0.25, Vector3(0.80, 1.72, 0.92))
	_add_ellipsoid("RightLeg", Vector3(0.18, 0.42, -0.01), 0.25, Vector3(0.80, 1.72, 0.92))

func _add_ellipsoid(part_name: String, position_value: Vector3, radius: float, scale_value: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.position = position_value
	var depth_ratio := scale_value.z / maxf(scale_value.x, 0.001)
	part.scale = Vector3(1.0, 1.0, depth_ratio)
	part.set_meta("body_part", part_name)
	part.set_meta("base_scale", part.scale)
	var capsule := CapsuleMesh.new()
	capsule.radius = radius * scale_value.x
	capsule.height = radius * 2.0 * scale_value.y
	capsule.radial_segments = 32
	capsule.rings = 12
	part.mesh = capsule
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_body_root.add_child(part)
	body_parts[part_name] = part

func _add_torso_blend(part_name: String, position_value: Vector3, scale_value: Vector3) -> void:
	var blend := MeshInstance3D.new()
	blend.name = part_name
	blend.position = position_value
	blend.scale = scale_value
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 32
	sphere.rings = 18
	blend.mesh = sphere
	blend.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_body_root.add_child(blend)
	_torso_blends.append(blend)

func _build_animation_system() -> void:
	animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	animation_player.root_node = NodePath("..")
	add_child(animation_player)
	var library := AnimationLibrary.new()
	for animation_name in ANIMATION_NAMES:
		library.add_animation(animation_name, _create_animation(animation_name))
	animation_player.add_animation_library("", library)
	animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	animation_tree.anim_player = NodePath("../AnimationPlayer")
	var state_machine := AnimationNodeStateMachine.new()
	for animation_name in ANIMATION_NAMES:
		var animation_node := AnimationNodeAnimation.new()
		animation_node.animation = animation_name
		state_machine.add_node(animation_name, animation_node)
	animation_tree.tree_root = state_machine
	add_child(animation_tree)
	animation_tree.active = true
	animation_playback = animation_tree.get("parameters/playback")

func _create_animation(animation_name: String) -> Animation:
	var animation := Animation.new()
	animation.length = 0.62 if animation_name == "Run" else 1.0
	if animation_name in ["Idle", "Walk", "Run", "Wave"]:
		animation.loop_mode = Animation.LOOP_LINEAR
	var positions := {
		"Torso": [Vector3(0, 1.04, 0)],
		"Head": [Vector3(0, 1.76, -0.015)],
		"LeftArm": [Vector3(-0.38, 1.04, 0)],
		"RightArm": [Vector3(0.38, 1.04, 0)],
		"LeftLeg": [Vector3(-0.18, 0.42, -0.01)],
		"RightLeg": [Vector3(0.18, 0.42, -0.01)]
	}
	var rotations := {
		"Torso": [Vector3.ZERO],
		"Head": [Vector3.ZERO],
		"LeftArm": [Vector3.ZERO],
		"RightArm": [Vector3.ZERO],
		"LeftLeg": [Vector3.ZERO],
		"RightLeg": [Vector3.ZERO]
	}
	var scales := {
		"Torso": [Vector3(1.0, 1.0, 0.795)],
		"Head": [Vector3(1.0, 1.0, 0.96)],
		"LeftArm": [Vector3(1.0, 1.0, 1.027)],
		"RightArm": [Vector3(1.0, 1.0, 1.027)],
		"LeftLeg": [Vector3(1.0, 1.0, 1.15)],
		"RightLeg": [Vector3(1.0, 1.0, 1.15)]
	}
	match animation_name:
		"Idle":
			positions["Torso"] = [Vector3(0, 1.04, 0), Vector3(0, 1.06, 0), Vector3(0, 1.04, 0)]
			positions["Head"] = [Vector3(0, 1.76, -0.015), Vector3(0, 1.77, -0.015), Vector3(0, 1.76, -0.015)]
		"Walk":
			rotations["LeftArm"] = [Vector3(0.34, 0, 0), Vector3(-0.34, 0, 0), Vector3(0.34, 0, 0)]
			rotations["RightArm"] = [Vector3(-0.34, 0, 0), Vector3(0.34, 0, 0), Vector3(-0.34, 0, 0)]
			rotations["LeftLeg"] = [Vector3(-0.30, 0, 0), Vector3(0.30, 0, 0), Vector3(-0.30, 0, 0)]
			rotations["RightLeg"] = [Vector3(0.30, 0, 0), Vector3(-0.30, 0, 0), Vector3(0.30, 0, 0)]
		"Run":
			rotations["LeftArm"] = [Vector3(0.58, 0, 0), Vector3(-0.58, 0, 0), Vector3(0.58, 0, 0)]
			rotations["RightArm"] = [Vector3(-0.58, 0, 0), Vector3(0.58, 0, 0), Vector3(-0.58, 0, 0)]
			rotations["LeftLeg"] = [Vector3(-0.48, 0, 0), Vector3(0.48, 0, 0), Vector3(-0.48, 0, 0)]
			rotations["RightLeg"] = [Vector3(0.48, 0, 0), Vector3(-0.48, 0, 0), Vector3(0.48, 0, 0)]
		"Jump":
			rotations["LeftArm"] = [Vector3.ZERO, Vector3(-0.45, 0, -0.32)]
			rotations["RightArm"] = [Vector3.ZERO, Vector3(-0.45, 0, 0.32)]
		"Crouch":
			positions["Torso"] = [Vector3(0, 0.88, 0)]
			positions["Head"] = [Vector3(0, 1.46, 0.02)]
			positions["LeftArm"] = [Vector3(-0.38, 0.88, 0)]
			positions["RightArm"] = [Vector3(0.38, 0.88, 0)]
			scales["Torso"] = [Vector3(1.0, 0.78, 0.795)]
		"Sit":
			positions["Torso"] = [Vector3(0, 0.88, 0)]
			positions["Head"] = [Vector3(0, 1.58, 0.02)]
			positions["LeftLeg"] = [Vector3(-0.20, 0.28, -0.20)]
			positions["RightLeg"] = [Vector3(0.20, 0.28, -0.20)]
			rotations["LeftLeg"] = [Vector3(1.05, 0, 0)]
			rotations["RightLeg"] = [Vector3(1.05, 0, 0)]
		"LieBack":
			positions["Torso"] = [Vector3(0, 0.42, 0)]
			positions["Head"] = [Vector3(0, 0.42, -0.68)]
			positions["LeftArm"] = [Vector3(-0.43, 0.42, 0)]
			positions["RightArm"] = [Vector3(0.43, 0.42, 0)]
			positions["LeftLeg"] = [Vector3(-0.18, 0.40, 0.72)]
			positions["RightLeg"] = [Vector3(0.18, 0.40, 0.72)]
			for part_name in rotations:
				rotations[part_name] = [Vector3(PI * 0.5, 0, 0)]
		"LieFront":
			positions["Torso"] = [Vector3(0, 0.38, 0)]
			positions["Head"] = [Vector3(0, 0.38, -0.68)]
			positions["LeftArm"] = [Vector3(-0.43, 0.38, 0)]
			positions["RightArm"] = [Vector3(0.43, 0.38, 0)]
			positions["LeftLeg"] = [Vector3(-0.18, 0.38, 0.72)]
			positions["RightLeg"] = [Vector3(0.18, 0.38, 0.72)]
			for part_name in rotations:
				rotations[part_name] = [Vector3(-PI * 0.5, 0, 0)]
		"ArmsUp":
			positions["LeftArm"] = [Vector3(-0.34, 1.54, 0)]
			positions["RightArm"] = [Vector3(0.34, 1.54, 0)]
			rotations["LeftArm"] = [Vector3(0, 0, -0.18)]
			rotations["RightArm"] = [Vector3(0, 0, 0.18)]
		"Wave":
			positions["RightArm"] = [Vector3(0.42, 1.48, 0), Vector3(0.48, 1.50, 0), Vector3(0.42, 1.48, 0)]
			rotations["RightArm"] = [Vector3(0, 0, -0.24), Vector3(0, 0, 0.18), Vector3(0, 0, -0.24)]
		"Lean":
			for part_name in rotations:
				rotations[part_name] = [Vector3(0, 0, 0.18)]
	for part_name in positions:
		_add_position_track(animation, part_name, positions[part_name])
		_add_rotation_track(animation, part_name, rotations[part_name])
		_add_scale_track(animation, part_name, scales[part_name])
	return animation

func _add_limb_swing(animation: Animation, amount: float) -> void:
	_add_rotation_track(animation, "LeftArm", [Vector3(amount, 0, 0), Vector3(-amount, 0, 0), Vector3(amount, 0, 0)])
	_add_rotation_track(animation, "RightArm", [Vector3(-amount, 0, 0), Vector3(amount, 0, 0), Vector3(-amount, 0, 0)])
	_add_rotation_track(animation, "LeftLeg", [Vector3(-amount, 0, 0), Vector3(amount, 0, 0), Vector3(-amount, 0, 0)])
	_add_rotation_track(animation, "RightLeg", [Vector3(amount, 0, 0), Vector3(-amount, 0, 0), Vector3(amount, 0, 0)])

func _add_rotation_track(animation: Animation, part_name: String, values: Array) -> void:
	_add_value_track(animation, NodePath("BodyParts/%s:rotation" % part_name), values)

func _add_position_track(animation: Animation, part_name: String, values: Array) -> void:
	_add_value_track(animation, NodePath("BodyParts/%s:position" % part_name), values)

func _add_scale_track(animation: Animation, part_name: String, values: Array) -> void:
	_add_value_track(animation, NodePath("BodyParts/%s:scale" % part_name), values)

func _add_value_track(animation: Animation, path: NodePath, values: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, path)
	for index in range(values.size()):
		var time := float(index) * animation.length / maxf(float(values.size() - 1), 1.0)
		animation.track_insert_key(track, time, values[index])

func _set_part_material(part: MeshInstance3D, color: Color) -> void:
	part.material_override = _material(color, 0.0, 0.72)
	if part.name == "Torso":
		for blend in _torso_blends:
			blend.material_override = _material(color, 0.0, 0.72)

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = clampf(metallic, 0.0, 1.0)
	material.roughness = clampf(roughness, 0.05, 1.0)
	return material
