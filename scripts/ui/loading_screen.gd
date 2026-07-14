extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")

const TIPS := [
	"Tip: kopieer een muurkleur voordat de seekerfase begint.",
	"Tip: sprinten helpt, maar maakt routekeuzes belangrijker.",
	"Tip: hurken verlaagt je profiel en geeft meer controle.",
	"Tip: seekers winnen door geduldig te scannen, niet door te gokken."
]

@onready var progress_bar: ProgressBar

func _ready() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_state(game_state.State.LOADING)
	UI_STYLE.apply_theme(self)
	_build()
	_start_loading()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.025, 0.03, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -310
	box.offset_top = -135
	box.offset_right = 310
	box.offset_bottom = 135
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	var title := Label.new()
	title.text = "COLOR HIDE ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_STYLE.title(title, 40)
	box.add_child(title)

	var tip := Label.new()
	var game_state = get_node_or_null("/root/GameState")
	var configured_tip := ""
	if game_state:
		configured_tip = game_state.loading_tip
	tip.text = configured_tip if configured_tip != "" else TIPS.pick_random()
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_color_override("font_color", Color(0.74, 0.96, 0.86))
	box.add_child(tip)

	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(620, 24)
	box.add_child(progress_bar)

func _start_loading() -> void:
	for i in range(1, 101):
		progress_bar.value = i
		await get_tree().process_frame
	var game_state = get_node_or_null("/root/GameState")
	var target_scene := "res://scenes/gameplay/TrainingArena.tscn"
	if game_state:
		target_scene = game_state.next_scene_path
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.finish_loading(target_scene)
	else:
		get_tree().change_scene_to_file(target_scene)
