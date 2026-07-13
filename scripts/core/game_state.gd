extends Node

enum State {
	MAIN_MENU,
	LOADING,
	PREPARATION,
	HIDING,
	SEEKING,
	ROUND_RESULTS,
	PAUSED
}

signal state_changed(state: State)

const MAIN_MENU_SCENE := "res://scenes/menus/MainMenu.tscn"
const LOADING_SCENE := "res://scenes/menus/LoadingScreen.tscn"
const TRAINING_SCENE := "res://scenes/gameplay/TrainingArena.tscn"

var current_state: State = State.MAIN_MENU
var previous_state: State = State.MAIN_MENU
var next_scene_path := TRAINING_SCENE
var loading_tip := ""

func set_state(state: State) -> void:
	if current_state == state:
		return
	previous_state = current_state
	current_state = state
	state_changed.emit(current_state)

func load_scene(target_scene: String, tip: String = "") -> void:
	next_scene_path = target_scene
	loading_tip = tip
	set_state(State.LOADING)
	get_tree().change_scene_to_file(LOADING_SCENE)

func go_to_main_menu() -> void:
	set_state(State.MAIN_MENU)
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func start_training() -> void:
	load_scene(TRAINING_SCENE, "Training")

