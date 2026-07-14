extends Node

signal paint_state_changed(color: Color, part_name: String, metallic: float, roughness: float)
signal paint_applied(part_name: String, color: Color)

var player: Node
var selected_part := "Torso"
var current_color := Color.WHITE
var metallic := 0.0
var roughness := 0.78
var brush_size := 0.25

func bind_player(next_player: Node) -> void:
    player = next_player
    if player and player.has_method("get_selected_part_name"):
        selected_part = player.get_selected_part_name()
        current_color = player.get_body_part_color(selected_part)
    _emit_state()

func set_selected_part(part_name: String) -> void:
    selected_part = part_name
    if player and player.has_method("set_selected_part"):
        player.set_selected_part(part_name)
    if player and player.has_method("get_body_part_color"):
        current_color = player.get_body_part_color(part_name)
    _emit_state()

func set_color(color: Color) -> void:
    current_color = color
    _emit_state()

func set_surface_material(next_metallic: float, next_roughness: float) -> void:
    metallic = clampf(next_metallic, 0.0, 1.0)
    roughness = clampf(next_roughness, 0.05, 1.0)
    _emit_state()

func apply() -> void:
    if not player or not player.has_method("set_body_part_style"):
        return
    player.set_body_part_style(selected_part, current_color, metallic, roughness)
    paint_applied.emit(selected_part, current_color)

func eyedropper() -> void:
    if player and player.has_method("sample_color"):
        player.sample_color()

func set_shadow_enabled(enabled: bool) -> void:
    if player and player.has_method("set_shadow_enabled"):
        player.set_shadow_enabled(enabled)

func _emit_state() -> void:
    paint_state_changed.emit(current_color, selected_part, metallic, roughness)

