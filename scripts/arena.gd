extends Node3D

func _ready():
    make_box(Vector3(0,-0.2,0), Vector3(24,0.4,24), Color(0.22,0.26,0.31))
    make_box(Vector3(0,2,-12), Vector3(24,4,0.5), Color(0.9,0.25,0.25))
    make_box(Vector3(0,2,12), Vector3(24,4,0.5), Color(0.2,0.55,0.9))
    make_box(Vector3(-12,2,0), Vector3(0.5,4,24), Color(0.25,0.8,0.45))
    make_box(Vector3(12,2,0), Vector3(0.5,4,24), Color(0.95,0.7,0.2))
    make_box(Vector3(-5,1,-4), Vector3(3,2,2), Color(0.55,0.3,0.15))
    make_box(Vector3(5,1,-3), Vector3(2,2,4), Color(0.25,0.65,0.7))
    make_box(Vector3(-4,1,5), Vector3(4,2,2), Color(0.7,0.25,0.65))
    make_box(Vector3(4,1,5), Vector3(2,2,3), Color(0.3,0.75,0.35))

func make_box(pos: Vector3, size: Vector3, color: Color):
    var body := StaticBody3D.new()
    body.position = pos
    body.set_meta("surface_color", color)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mesh.material_override = mat
    body.add_child(mesh)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    col.shape = shape
    body.add_child(col)
    add_child(body)
