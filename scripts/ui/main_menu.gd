extends Control

const UI_STYLE := preload("res://scripts/ui/ui_style.gd")
const LOGIN_SCENE := "res://scenes/login_menu.tscn"
const TRAINING_SETUP_SCENE := "res://scenes/menus/training_setup_menu.tscn"
const LOBBY_BROWSER_SCENE := "res://scenes/multiplayer/lobby.tscn"
const PRIVATE_LOBBY_SCENE := "res://scenes/multiplayer/private_lobby.tscn"
const PROFILE_SCENE := "res://scenes/menus/profile_menu.tscn"
const CUSTOMIZATION_SCENE := "res://scenes/menus/customization_menu.tscn"
const SETTINGS_SCENE := "res://scenes/menus/settings_menu.tscn"
const CREDITS_SCENE := "res://scenes/menus/credits_menu.tscn"

@onready var safe_area: MarginContainer = $SafeArea
@onready var left_menu: PanelContainer = $SafeArea/ContentLayout/LeftMenu
@onready var right_column: VBoxContainer = $SafeArea/ContentLayout/RightColumn
@onready var button_container: VBoxContainer = $SafeArea/ContentLayout/LeftMenu/MenuMargin/MenuContent/ButtonScroll/ButtonContainer
@onready var button_scroll: ScrollContainer = $SafeArea/ContentLayout/LeftMenu/MenuMargin/MenuContent/ButtonScroll
@onready var right_profile_panel: PanelContainer = $SafeArea/ContentLayout/RightColumn/RightProfilePanel
@onready var profile_heading: Label = $SafeArea/ContentLayout/RightColumn/RightProfilePanel/ProfileMargin/ProfileContent/ProfileHeading
@onready var profile_name_label: Label = $SafeArea/ContentLayout/RightColumn/RightProfilePanel/ProfileMargin/ProfileContent/ProfileNameLabel
@onready var profile_stats_label: Label = $SafeArea/ContentLayout/RightColumn/RightProfilePanel/ProfileMargin/ProfileContent/ProfileStatsLabel
@onready var device_label: Label = $SafeArea/ContentLayout/RightColumn/RightProfilePanel/ProfileMargin/ProfileContent/DeviceLabel
@onready var latest_session_panel: PanelContainer = $SafeArea/ContentLayout/RightColumn/LatestSessionPanel
@onready var latest_mode_label: Label = $SafeArea/ContentLayout/RightColumn/LatestSessionPanel/LatestMargin/LatestContent/LatestMode
@onready var latest_role_label: Label = $SafeArea/ContentLayout/RightColumn/LatestSessionPanel/LatestMargin/LatestContent/LatestRole
@onready var latest_result_label: Label = $SafeArea/ContentLayout/RightColumn/LatestSessionPanel/LatestMargin/LatestContent/LatestResult
@onready var latest_xp_label: Label = $SafeArea/ContentLayout/RightColumn/LatestSessionPanel/LatestMargin/LatestContent/LatestXP
@onready var news_panel: PanelContainer = $SafeArea/ContentLayout/RightColumn/NewsPanel
@onready var news_button: Button = $SafeArea/ContentLayout/RightColumn/NewsPanel/NewsMargin/NewsContent/NewsButton
@onready var logo_top: Label = $SafeArea/ContentLayout/LeftMenu/MenuMargin/MenuContent/Logo/LogoTop
@onready var logo_bottom: Label = $SafeArea/ContentLayout/LeftMenu/MenuMargin/MenuContent/Logo/LogoBottom
@onready var by_label: Label = $SafeArea/ContentLayout/LeftMenu/MenuMargin/MenuContent/Logo/ByLabel
@onready var subtitle: Label = $SafeArea/ContentLayout/LeftMenu/MenuMargin/MenuContent/Subtitle
@onready var bottom_info_bar: PanelContainer = $BottomInfoBar
@onready var transition_layer: ColorRect = $TransitionLayer
@onready var status_dialog: AcceptDialog = $StatusDialog
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var click_audio: AudioStreamPlayer = $ClickAudio
@onready var back_audio: AudioStreamPlayer = $BackAudio
@onready var menu_ambience: AudioStreamPlayer = $MenuAmbience
@onready var idle_audio: AudioStreamPlayer = $IdleAudio

var _menu_buttons: Array[Button] = []
var _is_transitioning := false
var _profile_data: Dictionary = {}
var _stats_data: Dictionary = {}
const XP_LEVEL_TARGET := 7500

func _ready() -> void:
	if not _is_logged_in():
		call_deferred("_go_to_login")
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_state(game_state.State.MAIN_MENU)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var cursor := get_node_or_null("/root/CursorManager")
	if cursor:
		cursor.set_mode(cursor.CursorMode.UI)
	UI_STYLE.apply_theme(self)
	_style_static_controls()
	_build_menu_buttons()
	_update_profile()
	var profile_service := get_node_or_null("/root/ProfileService")
	if profile_service:
		if not profile_service.profile_loaded.is_connected(_on_cloud_profile_loaded):
			profile_service.profile_loaded.connect(_on_cloud_profile_loaded)
		profile_service.load_profile()
	var stats_service := get_node_or_null("/root/StatsService")
	if stats_service and not stats_service.stats_loaded.is_connected(_on_cloud_stats_loaded):
		stats_service.stats_loaded.connect(_on_cloud_stats_loaded)
		stats_service.load_stats()
	_configure_layout()
	get_viewport().size_changed.connect(_configure_layout)
	call_deferred("_grab_initial_focus")
	_fade_in()
	_play_hook(menu_ambience)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if event.is_action_pressed("ui_cancel"):
		_play_hook(back_audio)
		_show_notice("Gebruik Uitloggen om terug te keren naar het loginmenu.")
		get_viewport().set_input_as_handled()

func _style_static_controls() -> void:
	left_menu.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.025, 0.055, 0.18), Color(0.12, 0.90, 0.82, 0.28), 8))
	right_profile_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.035, 0.09, 0.88), Color(0.55, 0.27, 0.95, 0.86)))
	latest_session_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.085, 0.92), Color(0.12, 0.68, 0.90, 0.82)))
	news_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.085, 0.92), Color(0.55, 0.25, 0.92, 0.82)))
	news_button.add_theme_stylebox_override("normal", _menu_button_style(Color(0.04, 0.08, 0.13, 0.95), Color(0.96, 0.70, 0.16, 0.88), 1))
	bottom_info_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.04, 0.075, 0.88), Color(0.12, 0.64, 0.72, 0.68), 6))
	logo_top.add_theme_font_size_override("font_size", 58)
	logo_top.add_theme_color_override("font_color", Color(0.18, 0.96, 0.84))
	logo_bottom.add_theme_font_size_override("font_size", 50)
	logo_bottom.add_theme_color_override("font_color", Color(0.72, 0.36, 0.96))
	by_label.add_theme_font_size_override("font_size", 14)
	by_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.24))
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.86, 0.96))
	profile_heading.add_theme_font_size_override("font_size", 18)
	profile_heading.add_theme_color_override("font_color", Color(0.25, 0.96, 0.84))
	profile_name_label.add_theme_font_size_override("font_size", 24)
	profile_name_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	profile_stats_label.add_theme_color_override("font_color", Color(0.74, 0.84, 0.95))
	latest_mode_label.add_theme_color_override("font_color", Color(0.24, 0.92, 0.84))
	latest_role_label.add_theme_color_override("font_color", Color(0.24, 0.92, 0.84))
	latest_result_label.add_theme_color_override("font_color", Color(0.98, 0.76, 0.22))
	latest_xp_label.add_theme_color_override("font_color", Color(0.76, 0.86, 0.96))
	news_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for child in news_panel.get_node("NewsMargin/NewsContent").get_children():
		if child is Label:
			child.add_theme_color_override("font_color", Color(0.84, 0.91, 0.98))
	device_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	device_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.32))
	for child in $BottomInfoBar/BottomInfoContent.get_children():
		if child is Label:
			child.add_theme_font_size_override("font_size", 13)
			child.add_theme_color_override("font_color", Color(0.80, 0.88, 0.96))

func _build_menu_buttons() -> void:
	_add_menu_button("QuickPlayButton", "▶  Snel spelen", "Matchmaking wordt later toegevoegd.", func(): _show_notice("Snel spelen wordt binnenkort toegevoegd."))
	_add_menu_button("TrainingButton", "◎  Training", "Oefen offline in de trainingsmap.", func(): _transition_to(TRAINING_SETUP_SCENE, false))
	_add_menu_button("MultiplayerButton", "♟  Multiplayer", "Bekijk de multiplayer-lobbybrowser.", func(): _transition_to(LOBBY_BROWSER_SCENE, false))
	_add_menu_button("PrivateLobbyButton", "▣  Private lobby", "Maak of join later een lobby met code.", func(): _transition_to(PRIVATE_LOBBY_SCENE, false))
	_add_menu_button("ProfileButton", "●  Profiel", "Bekijk je lokale profielinformatie.", func(): _transition_to(PROFILE_SCENE, false))
	_add_menu_button("CustomizationButton", "◆  Aanpassingen", "Kies later skins en cosmetische items.", func(): _transition_to(CUSTOMIZATION_SCENE, false))
	_add_menu_button("SettingsButton", "⚙  Instellingen", "Pas beeld, audio en besturing aan.", func(): _transition_to(SETTINGS_SCENE, false))
	_add_menu_button("CreditsButton", "★  Credits", "Bekijk de makers en technologie.", func(): _transition_to(CREDITS_SCENE, false))
	_add_menu_button("LogoutButton", "↪  Uitloggen", "Meld dit apparaat af.", _logout)
	var device := _device_service()
	if device == null or device.is_desktop():
		_add_menu_button("QuitButton", "⏻  Stoppen", "Sluit Meccha Chameleon.", _quit_game)
	_wire_controller_navigation()

func _add_menu_button(node_name: String, label_text: String, tooltip: String, callback: Callable) -> void:
	var button := Button.new()
	button.name = node_name
	button.text = label_text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0.0, 42.0)
	button.add_theme_font_size_override("font_size", 18)
	var normal_color := Color(0.025, 0.045, 0.085, 0.90)
	var accent_color := Color(0.12, 0.80, 0.78, 0.82)
	var text_color := Color(0.96, 0.98, 1.0)
	match node_name:
		"QuickPlayButton":
			normal_color = Color(0.02, 0.18, 0.20, 0.94)
			accent_color = Color(0.08, 0.96, 0.90, 1.0)
			text_color = Color(0.34, 1.0, 0.94)
		"LogoutButton":
			normal_color = Color(0.16, 0.12, 0.035, 0.92)
			accent_color = Color(1.0, 0.72, 0.12, 1.0)
			text_color = Color(1.0, 0.80, 0.24)
		"QuitButton":
			normal_color = Color(0.16, 0.025, 0.07, 0.92)
			accent_color = Color(1.0, 0.12, 0.34, 1.0)
			text_color = Color(1.0, 0.28, 0.46)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_stylebox_override("normal", _menu_button_style(normal_color, accent_color, 1))
	button.add_theme_stylebox_override("hover", _menu_button_style(Color(0.10, 0.055, 0.19, 0.97), Color(0.68, 0.34, 0.98, 0.98), 2))
	button.add_theme_stylebox_override("focus", _menu_button_style(Color(0.08, 0.06, 0.16, 0.98), Color(0.68, 0.34, 0.98, 1.0), 2, 10))
	button.add_theme_stylebox_override("pressed", _menu_button_style(Color(0.16, 0.13, 0.08, 1.0), Color(1.0, 0.76, 0.20, 1.0), 2))
	button.mouse_entered.connect(func(): _on_button_hover(button))
	button.focus_entered.connect(func(): _on_button_focus(button))
	button.pressed.connect(func(): _on_button_pressed(callback))
	button_container.add_child(button)
	_menu_buttons.append(button)

func _wire_controller_navigation() -> void:
	if _menu_buttons.is_empty():
		return
	for index in range(_menu_buttons.size()):
		var current := _menu_buttons[index]
		var previous := _menu_buttons[(index - 1 + _menu_buttons.size()) % _menu_buttons.size()]
		var next := _menu_buttons[(index + 1) % _menu_buttons.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(next)

func _on_button_hover(_button: Button) -> void:
	_play_hook(hover_audio)

func _on_button_focus(_button: Button) -> void:
	_play_hook(hover_audio)

func _on_button_pressed(callback: Callable) -> void:
	if _is_transitioning:
		return
	_play_hook(click_audio)
	callback.call()

func _update_profile() -> void:
	var session := get_node_or_null("/root/SessionManager")
	var player_name := _get_account_name(session)
	profile_heading.text = "MIJN ACCOUNT"
	by_label.text = "by %s" % player_name
	profile_name_label.text = player_name
	var history := get_node_or_null("/root/SessionHistoryService")
	var last_session: Dictionary = history.get_last_session() if history else {}
	_refresh_profile_stats(last_session)
	_update_latest_session(last_session)
	var device := _device_service()
	device_label.text = "Apparaat: %s" % (device.get_summary() if device else "Onbekend")

func _on_cloud_profile_loaded(profile: Dictionary) -> void:
	_profile_data = profile.duplicate(true)
	_update_profile()

func _on_cloud_stats_loaded(stats: Dictionary) -> void:
	_stats_data = stats.duplicate(true)
	_update_profile()

func _refresh_profile_stats(last_session: Dictionary) -> void:
	var level := maxi(int(_profile_data.get("level", 1)), 1)
	var profile_xp := maxi(int(_profile_data.get("xp", 0)), 0)
	var local_xp := maxi(int(_stats_data.get("xp_earned", 0)), 0)
	var xp := maxi(profile_xp, local_xp)
	var skin_id := str(_profile_data.get("selected_skin", "neutral"))
	var skin_name := "Neutraal" if skin_id.is_empty() or skin_id == "neutral" else skin_id.capitalize()
	var last_mode := str(last_session.get("mode", "Nog geen sessie"))
	profile_stats_label.text = "Level %d\nXP %d / %d\nStatus Online\nSkin %s\nLaatste modus %s\nRondes %d  Wins %d" % [
		level,
		xp,
		XP_LEVEL_TARGET,
		skin_name,
		last_mode,
		int(_stats_data.get("rounds", 0)),
		int(_stats_data.get("wins", 0))
	]

func _get_account_name(session: Node) -> String:
	var profile_name := str(_profile_data.get("username", "")).strip_edges()
	if not profile_name.is_empty():
		return profile_name
	if session and not str(session.get("display_name")).is_empty():
		return str(session.get("display_name"))
	if session and not str(session.get("email")).is_empty():
		return str(session.get("email"))
	return "MijnAccount"

func _last_session_mode() -> String:
	var history := get_node_or_null("/root/SessionHistoryService")
	var last_session: Dictionary = history.get_last_session() if history else {}
	return str(last_session.get("mode", "Nog geen sessie"))

func _update_latest_session(last_session: Dictionary) -> void:
	if last_session.is_empty():
		latest_mode_label.text = "Modus\nNog geen gespeelde sessie"
		latest_role_label.text = "Rol\n-"
		latest_result_label.text = "Resultaat\n-"
		latest_xp_label.text = "XP verdiend\n-"
		return
	latest_mode_label.text = "Modus\n%s" % str(last_session.get("mode", "Onbekend"))
	latest_role_label.text = "Rol\n%s" % str(last_session.get("role", "Onbekend"))
	latest_result_label.text = "Resultaat\n%s" % str(last_session.get("result", "Onbekend"))
	latest_xp_label.text = "XP verdiend\n+%d XP" % int(last_session.get("xp", 0))

func _configure_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var device := _device_service()
	var compact: bool = viewport_size.x < 900.0 or (device != null and device.is_mobile())
	if compact:
		safe_area.offset_left = 16.0
		safe_area.offset_top = 12.0
		safe_area.offset_right = -16.0
		safe_area.offset_bottom = -58.0
		left_menu.custom_minimum_size = Vector2.ZERO
		left_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_column.visible = false
		button_scroll.custom_minimum_size = Vector2(0.0, 190.0)
		logo_top.add_theme_font_size_override("font_size", 31)
		logo_bottom.add_theme_font_size_override("font_size", 28)
	else:
		safe_area.offset_left = 34.0
		safe_area.offset_top = 28.0
		safe_area.offset_right = -34.0
		safe_area.offset_bottom = -78.0
		left_menu.custom_minimum_size = Vector2(430.0, 0.0)
		left_menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		right_column.visible = true
		button_scroll.custom_minimum_size = Vector2(0.0, 280.0)
		logo_top.add_theme_font_size_override("font_size", 58)
		logo_bottom.add_theme_font_size_override("font_size", 50)
	for button in _menu_buttons:
		button.custom_minimum_size = Vector2(0.0, 54.0 if compact else 42.0)
		button.add_theme_font_size_override("font_size", 19 if compact else 18)
	bottom_info_bar.visible = viewport_size.y >= 330.0

func _grab_initial_focus() -> void:
	if not _menu_buttons.is_empty():
		_menu_buttons[0].grab_focus()

func _transition_to(path: String, use_loading: bool, tip := "") -> void:
	if _is_transitioning:
		return
	if not ResourceLoader.exists(path):
		_show_notice("Dit scherm ontbreekt nog: %s" % path)
		return
	_is_transitioning = true
	_set_menu_enabled(false)
	var tween := create_tween()
	tween.tween_property(transition_layer, "color:a", 1.0, 0.18)
	tween.finished.connect(func(): _complete_transition(path, use_loading, tip))

func _complete_transition(path: String, use_loading: bool, tip: String) -> void:
	var changed := false
	var manager := get_node_or_null("/root/SceneManager")
	if manager:
		changed = manager.change_scene(path, use_loading, tip)
	else:
		changed = get_tree().change_scene_to_file(path) == OK
	if not changed:
		_is_transitioning = false
		_set_menu_enabled(true)
		_fade_in()
		_show_notice("De scene kon niet worden geopend. Probeer opnieuw.")

func _logout() -> void:
	var session := get_node_or_null("/root/SessionManager")
	if session:
		session.logout()
	_transition_to(LOGIN_SCENE, false)

func _quit_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_set_menu_enabled(false)
	var tween := create_tween()
	tween.tween_property(transition_layer, "color:a", 1.0, 0.18)
	tween.finished.connect(func(): get_tree().quit())

func _go_to_login() -> void:
	var manager := get_node_or_null("/root/SceneManager")
	if manager:
		manager.change_scene(LOGIN_SCENE, false)
	else:
		get_tree().change_scene_to_file(LOGIN_SCENE)

func _is_logged_in() -> bool:
	var session := get_node_or_null("/root/SessionManager")
	return session != null and session.is_logged_in()

func _device_service() -> Node:
	return get_node_or_null("/root/DeviceService")

func _set_menu_enabled(enabled: bool) -> void:
	for button in _menu_buttons:
		button.disabled = not enabled

func _fade_in() -> void:
	transition_layer.color.a = 1.0
	var tween := create_tween()
	tween.tween_property(transition_layer, "color:a", 0.0, 0.28)

func _show_notice(message: String) -> void:
	status_dialog.dialog_text = message
	status_dialog.popup_centered()

func _play_hook(player: AudioStreamPlayer) -> void:
	if player.stream and not player.playing:
		player.play()

func _panel_style(background: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 10
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _menu_button_style(background: Color, border: Color, border_width: int, shadow_size: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	style.shadow_color = Color(border.r, border.g, border.b, 0.34)
	style.shadow_size = shadow_size
	return style
