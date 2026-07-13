extends Node

signal transition_started(target_path: String)
signal transition_finished(target_path: String)
signal transition_failed(target_path: String, message: String)

const LOADING_SCENE := "res://scenes/menus/LoadingScreen.tscn"

var is_transitioning := false
var pending_scene_path := ""
var last_error := ""

func change_scene(path: String, use_loading := true, tip := "") -> bool:
    if path.is_empty() or not ResourceLoader.exists(path):
        last_error = "Scene ontbreekt: %s" % path
        push_error(last_error)
        transition_failed.emit(path, last_error)
        return false
    if is_transitioning:
        return false
    if use_loading and path != LOADING_SCENE and ResourceLoader.exists(LOADING_SCENE):
        pending_scene_path = path
        is_transitioning = true
        var game_state := get_node_or_null("/root/GameState")
        if game_state:
            game_state.next_scene_path = path
            game_state.loading_tip = tip
            game_state.set_state(game_state.State.LOADING)
        transition_started.emit(path)
        var error := get_tree().change_scene_to_file(LOADING_SCENE)
        if error != OK:
            _fail_transition(path, "Laden van het laadscherm mislukte (%s)." % error)
        return error == OK
    return _perform_scene_change(path)

func finish_loading(path := "") -> bool:
    var target := path if not path.is_empty() else pending_scene_path
    if target.is_empty():
        target = "res://scenes/menus/main_menu.tscn"
    if not ResourceLoader.exists(target):
        _fail_transition(target, "De doel-scene van het laadscherm ontbreekt.")
        return false
    return _perform_scene_change(target)

func _perform_scene_change(path: String) -> bool:
    var error := get_tree().change_scene_to_file(path)
    if error != OK:
        _fail_transition(path, "Scene-overgang mislukt (%s)." % error)
        return false
    pending_scene_path = ""
    is_transitioning = false
    last_error = ""
    transition_finished.emit(path)
    return true

func _fail_transition(path: String, message: String) -> void:
    is_transitioning = false
    last_error = message
    push_error(message)
    transition_failed.emit(path, message)
