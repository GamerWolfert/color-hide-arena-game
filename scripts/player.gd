extends CharacterBody3D

@export var speed := 5.5
@export var sprint_speed := 8.0
@export var crouch_speed := 3.0
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.0025

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera3D
@onready var body_mesh: MeshInstance3D = $Body
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ray: RayCast3D = $Pivot/Camera3D/RayCast3D

var gravity := 9.8
var is_hider := true
var standing_height := 1.8
var crouching_height := 1.1

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    ray.add_exception(self)
    apply_color(Color.WHITE)

func _unhandled_input(event):
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        pivot.rotate_x(-event.relative.y * mouse_sensitivity)
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-55), deg_to_rad(55))
    elif event.is_action_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    elif event.is_action_pressed("toggle_role"):
        is_hider = !is_hider
        $"../UI".set_role(is_hider)
        apply_color(Color.WHITE if is_hider else Color(0.95, 0.2, 0.2))
    elif event.is_action_pressed("action"):
        if is_hider:
            sample_color()
        else:
            scan()

func _physics_process(delta):
    var crouching := Input.is_action_pressed("crouch")
    apply_crouch(crouching)

    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor() and not crouching:
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var forward := -camera.global_transform.basis.z
    var right := camera.global_transform.basis.x
    forward.y = 0
    right.y = 0
    forward = forward.normalized()
    right = right.normalized()
    var direction := (right * input_dir.x + forward * -input_dir.y).normalized()
    var current_speed := speed
    if crouching:
        current_speed = crouch_speed
    elif Input.is_action_pressed("sprint"):
        current_speed = sprint_speed

    if direction:
        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed
    else:
        velocity.x = move_toward(velocity.x, 0, current_speed)
        velocity.z = move_toward(velocity.z, 0, current_speed)

    move_and_slide()

func apply_crouch(crouching: bool):
    var target_height := crouching_height if crouching else standing_height
    var target_pivot_y := 0.35 if crouching else 0.65
    var target_body_scale_y := target_height / standing_height

    if collision_shape.shape is CapsuleShape3D:
        var capsule := collision_shape.shape as CapsuleShape3D
        capsule.height = target_height
    body_mesh.scale.y = target_body_scale_y
    pivot.position.y = move_toward(pivot.position.y, target_pivot_y, 0.12)

func sample_color():
    if ray.is_colliding():
        var collider = ray.get_collider()
        if collider and collider.has_meta("surface_color"):
            apply_color(collider.get_meta("surface_color"))
            $"../UI".show_message("Kleur gekopieerd")

func scan():
    if ray.is_colliding() and ray.get_collider() is CharacterBody3D:
        $"../UI".show_message("Hider gevonden!")
    else:
        $"../UI".show_message("Verkeerd doel")

func apply_color(c: Color):
    var mat := StandardMaterial3D.new()
    mat.albedo_color = c
    mat.roughness = 0.8
    body_mesh.material_override = mat
