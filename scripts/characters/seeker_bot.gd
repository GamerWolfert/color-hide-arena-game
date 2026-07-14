extends CharacterBody3D

signal bot_found_hider(target: Node)

@export var move_speed := 3.2
@export var investigate_radius := 4.2
@export var scan_interval := 1.2

var patrol_points: Array = []
var target_index := 0
var scan_timer := 0.0
var hider_nodes: Array = []
var navigation_agent: NavigationAgent3D
var investigating := false

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

func _physics_process(delta: float) -> void:
	_patrol(delta)
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = scan_interval
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
	for hider in hider_nodes:
		if not is_instance_valid(hider) or not hider.has_method("is_hidden_alive") or not hider.is_hidden_alive():
			continue
		var distance := global_position.distance_to(hider.global_position)
		var camouflage: float = hider.get_camouflage_percent() if hider.has_method("get_camouflage_percent") else 50.0
		if distance <= investigate_radius and camouflage < 92.0:
			if _has_line_of_sight(hider):
				bot_found_hider.emit(hider)
				return

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
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.72, 1.65, 0.42)
	mesh.position = Vector3(0, 0.82, 0)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.18, 0.22)
	mat.roughness = 0.75
	mesh.material_override = mat
	add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	col.shape = shape
	add_child(col)
