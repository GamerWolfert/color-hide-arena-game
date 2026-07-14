extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")
const PaintModeManagerScript := preload("res://scripts/gameplay/paint_mode_manager.gd")

signal paint_mode_toggled(open: bool)

var player: Node
var manager: Node
var panel: PanelContainer
var picker: ColorPickerButton
var part_selector: OptionButton
var current_swatch: ColorRect
var new_swatch: ColorRect
var rgb_label: Label
var hsv_label: Label
var hex_label: Label
var hex_input: LineEdit
var status_label: Label
var brightness_slider: HSlider
var saturation_slider: HSlider
var metallic_slider: HSlider
var roughness_slider: HSlider
var brush_slider: HSlider
var _shown := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    manager = PaintModeManagerScript.new()
    manager.name = "PaintModeManager"
    add_child(manager)
    manager.paint_state_changed.connect(_on_paint_state_changed)
    manager.paint_applied.connect(_on_paint_applied)
    _build()
    visible = false

func bind_player(next_player: Node) -> void:
    player = next_player
    manager.bind_player(player)
    if player.has_signal("eyedropper_previewed") and not player.eyedropper_previewed.is_connected(_on_eyedropper_previewed):
        player.eyedropper_previewed.connect(_on_eyedropper_previewed)
    if part_selector and player.has_method("get_body_part_names"):
        part_selector.clear()
        for part_name in player.get_body_part_names():
            part_selector.add_item(part_name)
        part_selector.select(max(player.get_body_part_names().find(manager.selected_part), 0))

func toggle() -> void:
    _shown = not _shown
    visible = _shown
    paint_mode_toggled.emit(_shown)
    mouse_filter = Control.MOUSE_FILTER_STOP if _shown else Control.MOUSE_FILTER_IGNORE
    if _shown:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        var input_service := get_node_or_null("/root/InputService")
        if input_service:
            input_service.set_touch_input_blocked(true)
    else:
        var input_service := get_node_or_null("/root/InputService")
        if input_service:
            input_service.set_touch_input_blocked(false)
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func close() -> void:
    if _shown:
        toggle()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("paint_mode"):
        toggle()
        get_viewport().set_input_as_handled()
    elif _shown and event.is_action_pressed("ui_cancel"):
        close()
        get_viewport().set_input_as_handled()

func _build() -> void:
    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.offset_left = -280
    panel.offset_top = -250
    panel.offset_right = 280
    panel.offset_bottom = 250
    panel.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.025, 0.045, 0.09, 0.97), Color(0.18, 0.86, 0.82, 0.95)))
    add_child(panel)
    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 8)
    panel.add_child(outer)
    var title := Label.new()
    title.text = "PAINT MODE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    UI_STYLE.title(title, 30)
    outer.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "Kopieer een oppervlak of verf één lichaamsdeel."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    outer.add_child(subtitle)

    var color_row := HBoxContainer.new()
    outer.add_child(color_row)
    picker = ColorPickerButton.new()
    picker.custom_minimum_size = Vector2(92, 54)
    picker.color = Color.WHITE
    picker.color_changed.connect(_on_picker_changed)
    color_row.add_child(picker)
    var swatches := VBoxContainer.new()
    color_row.add_child(swatches)
    current_swatch = _swatch(Color(0.82, 0.84, 0.78), "HUIDIGE KLEUR")
    new_swatch = _swatch(Color.WHITE, "NIEUWE KLEUR")
    swatches.add_child(current_swatch)
    swatches.add_child(new_swatch)

    rgb_label = Label.new()
    hsv_label = Label.new()
    hex_label = Label.new()
    hex_input = LineEdit.new()
    hex_input.placeholder_text = "HEX kleur, bijv. #2A8CFF"
    hex_input.text_submitted.connect(_on_hex_submitted)
    outer.add_child(rgb_label)
    outer.add_child(hsv_label)
    outer.add_child(hex_label)
    outer.add_child(hex_input)

    part_selector = OptionButton.new()
    part_selector.name = "BodyPartSelector"
    part_selector.add_item("Torso")
    part_selector.item_selected.connect(_on_part_selected)
    outer.add_child(part_selector)

    brightness_slider = _slider("Helderheid", 0.0, 2.0, 1.0)
    saturation_slider = _slider("Verzadiging", 0.0, 2.0, 1.0)
    metallic_slider = _slider("Metallic", 0.0, 1.0, 0.0)
    roughness_slider = _slider("Ruwheid", 0.05, 1.0, 0.78)
    brush_slider = _slider("Brushgrootte", 0.05, 1.0, 0.25)
    outer.add_child(brightness_slider)
    outer.add_child(saturation_slider)
    outer.add_child(metallic_slider)
    outer.add_child(roughness_slider)
    outer.add_child(brush_slider)
    brightness_slider.value_changed.connect(_on_adjustment_changed)
    saturation_slider.value_changed.connect(_on_adjustment_changed)
    metallic_slider.value_changed.connect(func(value): manager.set_surface_material(value, roughness_slider.value))
    roughness_slider.value_changed.connect(func(value): manager.set_surface_material(metallic_slider.value, value))
    brush_slider.value_changed.connect(func(value): manager.brush_size = value)

    var actions := HBoxContainer.new()
    outer.add_child(actions)
    var eyedropper := _button("Pipet", func(): manager.eyedropper())
    var apply := _button("Toepassen", func(): manager.apply())
    var close_button := _button("Sluiten", close)
    actions.add_child(eyedropper)
    actions.add_child(apply)
    actions.add_child(close_button)
    var shadow := CheckButton.new()
    shadow.text = "Schaduw aan"
    shadow.button_pressed = true
    shadow.toggled.connect(func(value): manager.set_shadow_enabled(value))
    outer.add_child(shadow)
    status_label = Label.new()
    status_label.text = "F openen/sluiten  •  Esc sluiten"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    outer.add_child(status_label)

func _swatch(color: Color, title: String) -> ColorRect:
    var row := HBoxContainer.new()
    var label := Label.new()
    label.text = title
    label.custom_minimum_size = Vector2(130, 22)
    row.add_child(label)
    var swatch := ColorRect.new()
    swatch.color = color
    swatch.custom_minimum_size = Vector2(80, 22)
    row.add_child(swatch)
    var wrapper := ColorRect.new()
    wrapper.color = Color(0, 0, 0, 0)
    wrapper.custom_minimum_size = Vector2(220, 24)
    wrapper.add_child(row)
    return wrapper

func _slider(label_text: String, minimum: float, maximum: float, value: float) -> HSlider:
    var slider := HSlider.new()
    slider.name = label_text.replace(" ", "")
    slider.min_value = minimum
    slider.max_value = maximum
    slider.value = value
    slider.tooltip_text = label_text
    slider.custom_minimum_size = Vector2(420, 24)
    return slider

func _button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(130, 42)
    button.add_theme_stylebox_override("normal", UI_STYLE.button(Color(0.06, 0.13, 0.18, 0.96), Color(0.55, 0.25, 0.92, 0.90)))
    button.pressed.connect(callback)
    return button

func _on_picker_changed(color: Color) -> void:
    manager.set_color(color)
    if hex_input:
        hex_input.text = "#%s" % color.to_html(false)

func _on_part_selected(index: int) -> void:
    manager.set_selected_part(part_selector.get_item_text(index))

func _on_adjustment_changed(_value: float) -> void:
    var color: Color = manager.current_color
    var hsv := Vector3(color.h, color.s, color.v)
    hsv.y = clampf(hsv.y * saturation_slider.value, 0.0, 1.0)
    hsv.z = clampf(hsv.z * brightness_slider.value, 0.0, 1.0)
    manager.set_color(Color.from_hsv(hsv.x, hsv.y, hsv.z, color.a))

func _on_eyedropper_previewed(color: Color, valid: bool) -> void:
    if valid:
        manager.set_color(color)
        if status_label:
            status_label.text = "Oppervlak gevonden  •  klik Toepassen"

func _on_paint_state_changed(color: Color, part_name: String, _metallic: float, _roughness: float) -> void:
    if not picker:
        return
    picker.color = color
    new_swatch.color = color
    hex_input.text = "#%s" % color.to_html(false)
    if player and player.has_method("get_body_part_color"):
        current_swatch.color = player.get_body_part_color(part_name)
    rgb_label.text = "RGB: %d, %d, %d" % [int(color.r * 255.0), int(color.g * 255.0), int(color.b * 255.0)]
    var hsv := Vector3(color.h, color.s, color.v)
    hsv_label.text = "HSV: %d°, %d%%, %d%%" % [int(hsv.x * 360.0), int(hsv.y * 100.0), int(hsv.z * 100.0)]
    hex_label.text = "HEX: #%s  •  DEEL: %s" % [color.to_html(false), part_name]

func _on_paint_applied(part_name: String, _color: Color) -> void:
    if status_label:
        status_label.text = "%s bijgewerkt" % part_name

func _on_hex_submitted(value: String) -> void:
    var parsed := Color.from_string(value.strip_edges(), manager.current_color)
    manager.set_color(parsed)
