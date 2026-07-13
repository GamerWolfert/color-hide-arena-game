extends CharacterBody3D

signal bot_found_hider(target: Node)

@export var move_speed := 3.2
@export var investigate_radius := 4.2
@export var scan_interval := 1.2

var patrol_points: Array = []
var target_index := 0
var scan_timer := 0.0
var hider_nodes: Array = []

func _ready() -> void:
	add_to_group("seekers")
	_build_body()

func setup(points: Array, hiders: Array) -> void:
	patrol_points = points
	hider_nodes = hiders
	if not patrol_points.is_empty():
		global_position = patrol_points[0].global_position

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
			hider.mark_found()
			bot_found_hider.emit(hider)
			return

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
