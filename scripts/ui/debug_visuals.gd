extends Node

var actors: Array = []
var name_labels_visible := false
var xray_visible := false

func _ready() -> void:
	if not OS.is_debug_build():
		set_process_unhandled_input(false)
		return
	var settings := get_node_or_null("/root/SettingsService")
	if settings:
		name_labels_visible = settings.debug_name_labels
		xray_visible = settings.debug_xray_enabled

func setup(next_actors: Array) -> void:
	actors = next_actors
	if not OS.is_debug_build():
		return
	_apply_name_labels()
	_apply_xray()

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("toggle_name_labels"):
		name_labels_visible = not name_labels_visible
		_apply_name_labels()
	if event.is_action_pressed("toggle_xray"):
		xray_visible = not xray_visible
		_apply_xray()

func _apply_name_labels() -> void:
	for actor in actors:
		if not is_instance_valid(actor):
			continue
		var label: Label3D = actor.get_node_or_null("DeveloperNameLabel")
		if name_labels_visible and not label:
			label = Label3D.new()
			label.name = "DeveloperNameLabel"
			label.position = Vector3(0, 2.25, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 32
			label.outline_size = 6
			label.modulate = Color(0.75, 1.0, 0.92)
			actor.add_child(label)
		if label:
			label.text = actor.name
			label.visible = name_labels_visible

func _apply_xray() -> void:
	for actor in actors:
		if not is_instance_valid(actor):
			continue
		for mesh in actor.find_children("*", "MeshInstance3D", true, false):
			var instance := mesh as MeshInstance3D
			if not instance:
				continue
			if xray_visible:
				var overlay := StandardMaterial3D.new()
				overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				overlay.no_depth_test = true
				overlay.albedo_color = Color(0.25, 1.0, 0.78, 0.34)
				instance.material_overlay = overlay
			else:
				instance.material_overlay = null
