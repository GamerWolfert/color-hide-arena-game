extends RefCounted
class_name UIStyle

static func apply_theme(control: Control) -> void:
	var theme := Theme.new()
	theme.default_font_size = 18
	control.theme = theme

static func panel(color := Color(0.06, 0.08, 0.11, 0.88), border := Color(0.18, 0.9, 0.72, 0.75)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func button(color := Color(0.10, 0.16, 0.20, 0.96), accent := Color(0.95, 0.72, 0.22, 1.0)) -> StyleBoxFlat:
	var style := panel(color, accent)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

static func title(label: Label, size := 46) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.96, 0.98, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

