extends CharacterBody3D

const MecchaCharacterScene := preload("res://scenes/characters/meccha_character.tscn")

signal bot_found_hider(target: Node)

@export var move_speed := 3.2
@export var investigate_radius := 4.2
@export var scan_interval := 1.2
@export var max_scanner_energy := 100.0
@export var scan_cooldown := 1.0

var patrol_points: Array = []
var target_index := 0
var scan_timer := 0.0
var hider_nodes: Array = []
var navigation_agent: NavigationAgent3D
var investigating := false
var scanner_energy := 100.0
var scanner_ready := true
var cooldown_timer := 0.0
var search_enabled := false

func _ready() -> void:
	add_to_group("seekers")
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.name = "NavigationAgent3D"
	navigation_agent.path_desired_distance = 0.7
	navigation_agent.target_desired_distance = 0.8
	add_child(navigation_agent)
	_build_body()

func setup(points: Array, hiders: Array) -> void:
	patrol_points = points
	hider_nodes = hiders
	if not patrol_points.is_empty():
		global_position = patrol_points[0].global_position
		navigation_agent.target_position = patrol_points[0].global_position

func reset_for_round() -> void:
	if patrol_points.is_empty():
		return
	target_index = 0
	scan_timer = 0.0
	scanner_energy = max_scanner_energy
	scanner_ready = true
	cooldown_timer = 0.0
	search_enabled = false
	velocity = Vector3.ZERO
	global_position = patrol_points[0].global_position
	if navigation_agent:
		navigation_agent.target_position = global_position

func _physics_process(delta: float) -> void:
	if not search_enabled:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	_patrol(delta)
	scan_timer -= delta
	if not scanner_ready:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			scanner_ready = true
	if scan_timer <= 0.0:
		scan_timer = scan_interval
		if scanner_ready:
			_scan_nearby_hiders()

func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	var target: Vector3 = patrol_points[target_index].global_position
	if navigation_agent and navigation_agent.get_navigation_map().is_valid():
		navigation_agent.target_position = target
		var next_path := navigation_agent.get_next_path_position()
		if next_path != Vector3.ZERO:
			target = next_path
	var flat_target := Vector3(target.x, global_position.y, target.z)
	var direction := flat_target - global_position
	if direction.length() < 0.45:
		target_index = (target_index + 1) % patrol_points.size()
		return
	direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	move_and_slide()
	look_at(Vector3(flat_target.x, global_position.y, flat_target.z), Vector3.UP)

func _scan_nearby_hiders() -> void:
	if scanner_energy <= 0.0:
		return
	scanner_ready = false
	cooldown_timer = scan_cooldown
	scanner_energy = maxf(scanner_energy - 6.0, 0.0)
	for hider in hider_nodes:
		if not is_instance_valid(hider) or not hider.has_method("is_hidden_alive") or not hider.is_hidden_alive():
			continue
		var distance := global_position.distance_to(hider.global_position)
		var camouflage: float = hider.get_camouflage_percent() if hider.has_method("get_camouflage_percent") else 50.0
		if distance <= investigate_radius and camouflage < 92.0:
			if _has_line_of_sight(hider):
				scanner_energy = minf(scanner_energy + 8.0, max_scanner_energy)
				bot_found_hider.emit(hider)
				return

func get_scanner_energy() -> float:
	return scanner_energy

func set_search_enabled(value: bool) -> void:
	search_enabled = value

func _has_line_of_sight(target: Node3D) -> bool:
	var space_state := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 1.2
	var to := target.global_position + Vector3.UP * 0.85
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return result.get("collider") == target

func _build_body() -> void:
	var character := MecchaCharacterScene.instantiate()
	character.name = "SeekerCharacter"
	add_child(character)
	if character.has_method("apply_color"):
		character.apply_color(Color(0.92, 0.12, 0.18))
	var visor := MeshInstance3D.new()
	visor.name = "ScannerVisor"
	var visor_mesh := SphereMesh.new()
	visor_mesh.radius = 0.20
	visor_mesh.height = 0.26
	visor.mesh = visor_mesh
	visor.position = Vector3(0.0, 1.78, -0.31)
	visor.scale = Vector3(1.0, 0.72, 0.24)
	var visor_material := StandardMaterial3D.new()
	visor_material.albedo_color = Color(0.18, 0.035, 0.05)
	visor_material.emission_enabled = true
	visor_material.emission = Color(0.9, 0.06, 0.08)
	visor_material.emission_energy_multiplier = 1.5
	visor.material_override = visor_material
	add_child(visor)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	col.shape = shape
	add_child(col)
