extends CharacterBody3D

const PoseManagerScript := preload("res://scripts/characters/pose_manager.gd")

signal role_changed(is_hider: bool)
signal color_sampled(color: Color)
signal eyedropper_previewed(color: Color, valid: bool)
signal seeker_scanned(found: bool, target: Node, energy: float)
signal camouflage_changed(percent: float, selected_part: String, pose_name: String)
signal scanner_fired(hit: bool)
signal pose_changed(pose_name: String)
signal taunt_requested
signal interaction_requested
signal scanner_cooldown_changed(ready: bool, seconds_left: float)

@export var walk_speed := 5.5
@export var sprint_speed := 8.5
@export var crouch_speed := 3.0
@export var acceleration := 18.0
@export var deceleration := 22.0
@export var air_control := 0.35
@export var jump_velocity := 5.2
@export var gravity := 18.0
@export var controller_look_speed := 2.8
@export var scan_cooldown := 0.9
@export var max_scanner_energy := 100.0

@onready var yaw_root: Node3D = $YawRoot
@onready var pitch_root: Node3D = $YawRoot/PitchRoot
@onready var spring_arm: SpringArm3D = $YawRoot/PitchRoot/SpringArm3D
@onready var camera: Camera3D = $YawRoot/PitchRoot/SpringArm3D/Camera3D
@onready var ray: RayCast3D = $YawRoot/PitchRoot/SpringArm3D/Camera3D/RayCast3D
@onready var body_mesh: MeshInstance3D = $Body
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_hider := true
var input_locked := false
var scanner_energy := 100.0
var scanner_ready := true
var sampled_color := Color.WHITE
var camouflage_percent := 0.0
var selected_part_index := 1
var pose_index := 0
var body_parts := {}
var last_surface_color := Color.WHITE
var last_surface_distance := 99.0
var last_frame_position := Vector3.ZERO
var shadow_enabled := true
var shadow_toggle_allowed := true
var rotation_locked := false
var pose_manager: Node
var mobile_crouching := false
var mobile_eyedropper := false
var scanner_mesh: MeshInstance3D
var _pitch := deg_to_rad(-12.0)
var _standing_height := 1.8
var _crouching_height := 1.1
var _scan_timer := 0.0
var _part_names := ["Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"]
var _pose_names := PoseManagerScript.POSE_NAMES

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ray.add_exception(self)
	last_frame_position = global_position
	_build_body_parts()
	pose_manager = PoseManagerScript.new()
	pose_manager.name = "PoseManager"
	add_child(pose_manager)
	pose_manager.setup(body_parts)
	pose_manager.pose_changed.connect(_on_pose_changed)
	_build_scanner()
	apply_color(Color(0.82, 0.84, 0.78))
	_apply_camera_settings()
	var settings = get_node_or_null("/root/SettingsService")
	if settings:
		settings.settings_changed.connect(_apply_camera_settings)

func _unhandled_input(event: InputEvent) -> void:
	if input_locked:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not rotation_locked:
			var sensitivity := _mouse_sensitivity()
			_rotate_camera(-event.relative.x * sensitivity, -event.relative.y * sensitivity)
	elif event.is_action_pressed("toggle_role"):
		set_hider(not is_hider)
	elif event.is_action_pressed("next_body_part"):
		_select_next_part()
	elif event.is_action_pressed("pose_next"):
		_next_pose()
	elif event.is_action_pressed("pose_previous"):
		_previous_pose()
	elif event.is_action_pressed("sample_color"):
		sample_color()
	elif event.is_action_pressed("paint_part"):
		paint_selected_part()
	elif event.is_action_pressed("action"):
		if is_hider:
			sample_color()
			paint_selected_part()
		else:
			scan()
	elif event.is_action_pressed("taunt"):
		taunt()
	elif event.is_action_pressed("ui_accept"):
		interaction_requested.emit()
	elif event.is_action_pressed("scanner_primary") and not is_hider:
		scan()
	elif event.is_action_pressed("toggle_rotation_lock"):
		rotation_locked = not rotation_locked
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(spring_arm.spring_length - 0.35)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(spring_arm.spring_length + 0.35)

func _physics_process(delta: float) -> void:
	if (Input.is_action_pressed("eyedropper") or mobile_eyedropper) and is_hider:
		_preview_surface_color()
	if input_locked:
		_slow_to_stop(delta)
		move_and_slide()
		return

	_handle_controller_look(delta)
	_update_scanner(delta)
	var crouching := Input.is_action_pressed("crouch") or mobile_crouching
	_apply_crouch(crouching, delta)

	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not crouching:
			velocity.y = jump_velocity
	else:
		velocity.y -= gravity * delta

	var input_dir := Vector2.ZERO
	var input_service := get_node_or_null("/root/InputService")
	if input_service:
		input_dir = input_service.get_move_vector()
	else:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := _camera_relative_direction(input_dir)
	var target_speed := _target_speed(crouching)
	var control := 1.0 if is_on_floor() else air_control
	var rate := acceleration if direction.length() > 0.0 else deceleration
	var target_velocity := direction * target_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * control * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * control * delta)

	move_and_slide()
	_update_camouflage()
	last_frame_position = global_position

func reset_to_spawn(spawn_transform: Transform3D, hider: bool) -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	set_hider(hider)
	input_locked = false

func set_hider(value: bool) -> void:
	is_hider = value
	scanner_energy = max_scanner_energy
	if is_hider:
		apply_color(Color(0.82, 0.84, 0.78))
	else:
		apply_color(Color(0.95, 0.20, 0.20))
	if scanner_mesh:
		scanner_mesh.visible = not is_hider
	role_changed.emit(is_hider)

func jump() -> void:
	if not input_locked and is_on_floor() and not (Input.is_action_pressed("crouch") or mobile_crouching):
		velocity.y = jump_velocity

func set_mobile_crouching(value: bool) -> void:
	mobile_crouching = value

func set_mobile_eyedropper(value: bool) -> void:
	mobile_eyedropper = value
	if not value:
		eyedropper_previewed.emit(sampled_color, false)

func interact() -> void:
	interaction_requested.emit()
	if is_hider:
		sample_color()
	else:
		scan()

func taunt() -> void:
	taunt_requested.emit()

func set_round_input_locked(value: bool) -> void:
	input_locked = value

func set_shadow_enabled(value: bool) -> void:
	if not shadow_toggle_allowed:
		return
	shadow_enabled = value
	for part in body_parts.values():
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_shadow_policy(allowed: bool) -> void:
	shadow_toggle_allowed = allowed

func sample_color() -> void:
	var sample := _read_surface_sample()
	if not sample.is_empty():
		sampled_color = sample.color
		last_surface_color = sampled_color
		last_surface_distance = sample.distance
		color_sampled.emit(sampled_color)
		eyedropper_previewed.emit(sampled_color, true)

func _preview_surface_color() -> void:
	var sample := _read_surface_sample()
	if sample.is_empty():
		eyedropper_previewed.emit(Color.WHITE, false)
	else:
		eyedropper_previewed.emit(sample.color, true)

func _read_surface_sample() -> Dictionary:
	ray.force_raycast_update()
	if not ray.is_colliding():
		return {}
	var collider := ray.get_collider()
	if not collider or collider == self:
		return {}
	var material_node: Node = collider
	var color := Color.WHITE
	while material_node:
		if material_node.has_meta("transparent_surface") and bool(material_node.get_meta("transparent_surface")):
			return {}
		if material_node.has_meta("surface_color"):
			color = material_node.get_meta("surface_color")
			break
		material_node = material_node.get_parent()
	if color == Color.WHITE:
		var mesh := collider as MeshInstance3D
		if mesh:
			var active_material := mesh.get_active_material(0)
			if active_material is BaseMaterial3D:
				if active_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					return {}
				color = active_material.albedo_color
	if color == Color.WHITE and not collider.has_meta("surface_color"):
		return {}
	return {"color": color, "distance": ray.global_position.distance_to(ray.get_collision_point())}

func scan() -> void:
	if not scanner_ready or scanner_energy <= 0.0:
		seeker_scanned.emit(false, null, scanner_energy)
		return
	scanner_ready = false
	_scan_timer = scan_cooldown
	_animate_scanner()
	ray.force_raycast_update()
	var target: Node = ray.get_collider() if ray.is_colliding() else null
	var found := false
	if target and target.is_in_group("hiders") and target.has_method("is_hidden_alive") and target.is_hidden_alive():
		found = true
	if not found:
		scanner_energy = max(scanner_energy - 12.0, 0.0)
	else:
		scanner_energy = min(scanner_energy + 4.0, max_scanner_energy)
	scanner_fired.emit(found)
	seeker_scanned.emit(found, target, scanner_energy)

func _build_scanner() -> void:
	scanner_mesh = MeshInstance3D.new()
	scanner_mesh.name = "ScannerBlaster"
	var box := BoxMesh.new()
	box.size = Vector3(0.16, 0.16, 0.52)
	scanner_mesh.mesh = box
	scanner_mesh.position = Vector3(0.48, -0.34, -0.82)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.9, 0.78)
	material.emission_enabled = true
	material.emission = Color(0.1, 0.45, 0.38)
	scanner_mesh.material_override = material
	scanner_mesh.visible = false
	camera.add_child(scanner_mesh)

func _animate_scanner() -> void:
	if not scanner_mesh:
		return
	var start_position := Vector3(0.48, -0.34, -0.82)
	var tween := create_tween()
	tween.tween_property(scanner_mesh, "position", start_position + Vector3(0.0, 0.0, -0.18), 0.06)
	tween.tween_property(scanner_mesh, "position", start_position, 0.14)

func apply_color(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.74
	body_mesh.material_override = mat
	for part_name in body_parts.keys():
		_set_part_color(part_name, color)

func paint_selected_part(color: Color = Color(-1, -1, -1, -1)) -> void:
	if not is_hider:
		return
	var part_name: String = _part_names[selected_part_index]
	var paint_color := sampled_color if color.r < 0.0 else color
	_set_part_color(part_name, paint_color)
	_update_camouflage()

func set_body_part_style(part_name: String, color: Color, metallic := 0.0, roughness := 0.78) -> void:
	if not body_parts.has(part_name):
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = clampf(metallic, 0.0, 1.0)
	mat.roughness = clampf(roughness, 0.05, 1.0)
	body_parts[part_name].material_override = mat
	_update_camouflage()

func get_body_part_color(part_name: String) -> Color:
	var part: MeshInstance3D = body_parts.get(part_name)
	if part and part.material_override is StandardMaterial3D:
		return part.material_override.albedo_color
	return Color.WHITE

func get_body_part_names() -> Array[String]:
	return _part_names.duplicate()

func get_selected_part_name() -> String:
	return _part_names[selected_part_index]

func set_selected_part(part_name: String) -> void:
	var index := _part_names.find(part_name)
	if index >= 0:
		selected_part_index = index
		_highlight_selected_part()
		_update_camouflage()

func get_camouflage_percent() -> float:
	return camouflage_percent

func get_scanner_energy() -> float:
	return scanner_energy

func _camera_relative_direction(input_dir: Vector2) -> Vector3:
	if input_dir.length() <= 0.0:
		return Vector3.ZERO
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	return (right * input_dir.x + forward * -input_dir.y).normalized()

func _target_speed(crouching: bool) -> float:
	if crouching:
		return crouch_speed
	if Input.is_action_pressed("sprint"):
		return sprint_speed
	return walk_speed

func _rotate_camera(yaw_delta: float, pitch_delta: float) -> void:
	yaw_root.rotate_y(yaw_delta)
	_pitch = clamp(_pitch + pitch_delta, deg_to_rad(-55.0), deg_to_rad(35.0))
	pitch_root.rotation.x = _pitch

func _handle_controller_look(delta: float) -> void:
	if rotation_locked:
		return
	var look := Vector2.ZERO
	var input_service := get_node_or_null("/root/InputService")
	if input_service:
		look = input_service.get_look_vector()
	else:
		look = Vector2(
			Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
		)
	if look.length() > 0.05:
		var settings := get_node_or_null("/root/SettingsService")
		var sensitivity := controller_look_speed
		if settings:
			sensitivity = settings.controller_sensitivity
		var pitch_input := -look.y
		if settings and settings.invert_y:
			pitch_input = look.y
		_rotate_camera(-look.x * sensitivity * delta, pitch_input * sensitivity * delta)

func _apply_crouch(crouching: bool, delta: float) -> void:
	var target_height := _crouching_height if crouching else _standing_height
	var target_scale := target_height / _standing_height
	var target_pitch_y := 0.95 if crouching else 1.25
	if collision_shape.shape is CapsuleShape3D:
		var capsule := collision_shape.shape as CapsuleShape3D
		capsule.height = move_toward(capsule.height, target_height, 5.0 * delta)
	body_mesh.scale.y = move_toward(body_mesh.scale.y, target_scale, 5.0 * delta)
	yaw_root.position.y = move_toward(yaw_root.position.y, target_pitch_y, 5.0 * delta)
	if crouching and pose_index == 0:
		_set_pose(3)

func _slow_to_stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta

func _apply_camera_settings() -> void:
	spring_arm.spring_length = 4.2
	camera.current = true

func _mouse_sensitivity() -> float:
	var settings = get_node_or_null("/root/SettingsService")
	if settings:
		return settings.mouse_sensitivity
	return 0.0025

func _build_body_parts() -> void:
	body_mesh.visible = false
	var root := Node3D.new()
	root.name = "BodyParts"
	add_child(root)
	_add_part(root, "Torso", Vector3(0, 1.05, 0), Vector3(0.72, 0.90, 0.34), Color(0.82, 0.84, 0.78))
	_add_part(root, "Head", Vector3(0, 1.70, 0), Vector3(0.42, 0.42, 0.42), Color(0.82, 0.84, 0.78))
	_add_part(root, "LeftArm", Vector3(-0.55, 1.10, 0), Vector3(0.22, 0.82, 0.22), Color(0.82, 0.84, 0.78))
	_add_part(root, "RightArm", Vector3(0.55, 1.10, 0), Vector3(0.22, 0.82, 0.22), Color(0.82, 0.84, 0.78))
	_add_part(root, "LeftLeg", Vector3(-0.22, 0.42, 0), Vector3(0.26, 0.78, 0.26), Color(0.82, 0.84, 0.78))
	_add_part(root, "RightLeg", Vector3(0.22, 0.42, 0), Vector3(0.26, 0.78, 0.26), Color(0.82, 0.84, 0.78))
	_highlight_selected_part()

func _add_part(root: Node3D, part_name: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.position = pos
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.set_meta("body_part", part_name)
	root.add_child(mesh)
	body_parts[part_name] = mesh
	_set_part_color(part_name, color)

func _set_part_color(part_name: String, color: Color) -> void:
	if not body_parts.has(part_name):
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	body_parts[part_name].material_override = mat

func _select_next_part() -> void:
	selected_part_index = (selected_part_index + 1) % _part_names.size()
	_highlight_selected_part()
	_update_camouflage()

func _highlight_selected_part() -> void:
	for i in range(_part_names.size()):
		var part: MeshInstance3D = body_parts.get(_part_names[i])
		if part:
			part.scale = Vector3.ONE * (1.08 if i == selected_part_index else 1.0)

func _next_pose() -> void:
	_set_pose(pose_index + 1)

func _previous_pose() -> void:
	_set_pose(pose_index - 1)

func _set_pose(index: int) -> void:
	if pose_manager:
		pose_manager.set_pose(index)
	else:
		pose_index = posmod(index, _pose_names.size())
		_apply_pose()
	_update_camouflage()

func _on_pose_changed(index: int, pose_name: String) -> void:
	pose_index = index
	pose_changed.emit(pose_name)
	_update_camouflage()

func _apply_pose() -> void:
	if pose_manager:
		pose_manager.pose_index = pose_index
		pose_manager.apply_pose()
		return
	var left_arm: Node3D = body_parts.get("LeftArm")
	var right_arm: Node3D = body_parts.get("RightArm")
	var torso: Node3D = body_parts.get("Torso")
	var head: Node3D = body_parts.get("Head")
	if not left_arm or not right_arm or not torso or not head:
		return
	for part in body_parts.values():
		part.rotation = Vector3.ZERO
		part.scale = Vector3.ONE
		part.position.z = 0.0
	torso.position = Vector3(0, 1.05, 0)
	head.position = Vector3(0, 1.70, 0)
	left_arm.position = Vector3(-0.55, 1.10, 0)
	right_arm.position = Vector3(0.55, 1.10, 0)
	body_parts["LeftLeg"].position = Vector3(-0.22, 0.42, 0)
	body_parts["RightLeg"].position = Vector3(0.22, 0.42, 0)
	match pose_index:
		1:
			torso.scale.y = 0.82
			head.position.y = 1.48
		2:
			left_arm.rotation.z = deg_to_rad(-38)
			right_arm.rotation.z = deg_to_rad(38)
			left_arm.position.y = 1.48
			right_arm.position.y = 1.48
		3:
			torso.rotation.z = deg_to_rad(9)
			head.rotation.z = deg_to_rad(9)
		4:
			for part in body_parts.values():
				part.position.z = -0.22
			torso.rotation.x = deg_to_rad(8)
		_:
			torso.scale.y = 1.0
			head.position.y = 1.70
	_highlight_selected_part()

func _update_camouflage() -> void:
	if not is_hider:
		return
	var average := Color.BLACK
	for part in body_parts.values():
		var mat: StandardMaterial3D = part.material_override
		average += mat.albedo_color
	average /= max(body_parts.size(), 1)
	var color_diff: float = abs(average.r - last_surface_color.r) + abs(average.g - last_surface_color.g) + abs(average.b - last_surface_color.b)
	var color_score: float = clamp(1.0 - color_diff / 3.0, 0.0, 1.0)
	var distance_score: float = clamp(1.0 - last_surface_distance / 7.0, 0.0, 1.0)
	var movement := global_position.distance_to(last_frame_position)
	var movement_score: float = clamp(1.0 - movement * 25.0, 0.0, 1.0)
	var part_score := 0.0
	for part in body_parts.values():
		var part_material: StandardMaterial3D = part.material_override
		var part_diff: float = abs(part_material.albedo_color.r - last_surface_color.r) + abs(part_material.albedo_color.g - last_surface_color.g) + abs(part_material.albedo_color.b - last_surface_color.b)
		part_score += clampf(1.0 - part_diff / 3.0, 0.0, 1.0)
	part_score /= max(body_parts.size(), 1)
	var pose_scores: Array[float] = [0.72, 0.78, 0.82, 0.86, 0.84, 0.90, 0.88, 0.86, 0.89, 0.80]
	var pose_score: float = pose_scores[pose_index]
	var visibility_score := clampf(1.0 - abs(global_position.y - 1.0) * 0.08, 0.70, 1.0)
	var shadow_score := 1.0 if shadow_enabled else 0.96
	camouflage_percent = round((color_score * 0.26 + part_score * 0.18 + distance_score * 0.18 + movement_score * 0.14 + pose_score * 0.14 + visibility_score * 0.06 + shadow_score * 0.04) * 100.0)
	camouflage_changed.emit(camouflage_percent, _part_names[selected_part_index], _pose_names[pose_index])

func _update_scanner(delta: float) -> void:
	if not scanner_ready:
		_scan_timer -= delta
		if _scan_timer <= 0.0:
			scanner_ready = true
			_scanner_cooldown_changed(true, 0.0)
		else:
			_scanner_cooldown_changed(false, _scan_timer)
	if not is_hider:
		scanner_energy = min(scanner_energy + 4.0 * delta, max_scanner_energy)

func _set_zoom(value: float) -> void:
	spring_arm.spring_length = clampf(value, 2.0, 7.0)

func _scanner_cooldown_changed(ready: bool, seconds_left: float) -> void:
	scanner_cooldown_changed.emit(ready, seconds_left)
