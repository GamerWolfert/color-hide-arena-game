extends Control

const MAIN_MENU_SCENE := "res://scenes/menus/main_menu.tscn"
const REQUEST_TIMEOUT := 22.0

enum AuthMode {
	LOGIN,
	REGISTER
}

@onready var username_input: LineEdit = $UiLayer/UsernameInput
@onready var email_input: LineEdit = $UiLayer/EmailInput
@onready var password_input: LineEdit = $UiLayer/PasswordInput
@onready var confirm_password_input: LineEdit = $UiLayer/ConfirmPasswordInput
@onready var password_eye_button: Button = $UiLayer/PasswordEyeButton
@onready var confirm_eye_button: Button = $UiLayer/ConfirmEyeButton
@onready var register_button: Button = $UiLayer/RegisterButton
@onready var login_button: Button = $UiLayer/LoginButton
@onready var loading_indicator: ProgressBar = $UiLayer/LoadingIndicator
@onready var login_username_mask: Control = $UiLayer/LoginUsernameMask
@onready var login_confirm_mask: Control = $UiLayer/LoginConfirmMask
@onready var status_backdrop: ColorRect = $UiLayer/StatusBackdrop
@onready var status_label: Label = $UiLayer/StatusLabel

var _is_loading := false
var _pending_action := ""
var _timeout_left := 0.0
var _mode: AuthMode = AuthMode.LOGIN

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_ensure_main_menu_scene()
	_connect_signals()
	_apply_initial_state()
	_try_continue_session()

func _process(delta: float) -> void:
	if not _is_loading:
		return
	loading_indicator.value = fmod(loading_indicator.value + delta * 85.0, 100.0)
	_timeout_left -= delta
	if _timeout_left <= 0.0:
		_finish_request(false, "De aanvraag duurt te lang. Controleer je verbinding en probeer opnieuw.")

func _on_login_button_pressed() -> void:
	if _is_loading:
		return
	if _mode == AuthMode.REGISTER:
		_set_mode(AuthMode.LOGIN)
		return
	_submit_login()

func _on_register_button_pressed() -> void:
	if _is_loading:
		return
	if _mode == AuthMode.LOGIN:
		_set_mode(AuthMode.REGISTER)
		return
	_submit_registration()

func _submit_login() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text
	if email.is_empty():
		_show_error("Vul je e-mailadres in.")
		email_input.grab_focus()
		return
	if not _is_valid_email(email):
		_show_error("Vul een geldig e-mailadres in.")
		email_input.grab_focus()
		return
	if password.is_empty():
		_show_error("Vul je wachtwoord in.")
		password_input.grab_focus()
		return
	_start_request("login", "Inloggen...")
	var auth := _auth_service()
	if auth == null:
		_finish_request(false, "AuthService is niet beschikbaar.")
		return
	auth.login(email, password)

func _submit_registration() -> void:
	var username := username_input.text.strip_edges()
	var email := email_input.text.strip_edges()
	var password := password_input.text
	var confirm_password := confirm_password_input.text
	if username.is_empty():
		_show_error("Vul een gebruikersnaam in.")
		username_input.grab_focus()
		return
	if username.length() < 3:
		_show_error("Gebruik een gebruikersnaam van minimaal 3 tekens.")
		username_input.grab_focus()
		return
	if email.is_empty():
		_show_error("Vul je e-mailadres in.")
		email_input.grab_focus()
		return
	if not _is_valid_email(email):
		_show_error("Vul een geldig e-mailadres in.")
		email_input.grab_focus()
		return
	if password.length() < 8:
		_show_error("Gebruik een wachtwoord van minimaal 8 tekens.")
		password_input.grab_focus()
		return
	if password != confirm_password:
		_show_error("De wachtwoorden zijn niet gelijk.")
		confirm_password_input.grab_focus()
		return
	_start_request("signup", "Account maken...")
	var auth := _auth_service()
	if auth == null:
		_finish_request(false, "AuthService is niet beschikbaar.")
		return
	auth.sign_up(email, password, username)

func _on_login_finished(success: bool, message: String) -> void:
	if _pending_action != "login":
		return
	if success:
		var session := _session_manager()
		if session == null or not session.is_logged_in():
			_finish_request(false, "Inloggen is gelukt, maar de sessie is ongeldig. Probeer opnieuw.")
			return
		_finish_request(true, "Inloggen gelukt. Je gaat naar het menu...")
		_go_to_main_menu.call_deferred()
	else:
		_finish_request(false, _friendly_error(message))

func _on_signup_finished(success: bool, message: String) -> void:
	if _pending_action != "signup":
		return
	if success:
		var session := _session_manager()
		if session != null and session.is_logged_in():
			_finish_request(true, "Account gemaakt. Je gaat naar het menu...")
			_go_to_main_menu.call_deferred()
			return
		_set_mode(AuthMode.LOGIN, false)
		_finish_request(true, "Account gemaakt. Controleer je e-mail om je account te bevestigen.")
	else:
		_finish_request(false, _friendly_error(message))

func _connect_signals() -> void:
	if not register_button.pressed.is_connected(_on_register_button_pressed):
		register_button.pressed.connect(_on_register_button_pressed)
	if not login_button.pressed.is_connected(_on_login_button_pressed):
		login_button.pressed.connect(_on_login_button_pressed)
	if not password_eye_button.pressed.is_connected(_on_password_eye_pressed):
		password_eye_button.pressed.connect(_on_password_eye_pressed)
	if not confirm_eye_button.pressed.is_connected(_on_confirm_eye_pressed):
		confirm_eye_button.pressed.connect(_on_confirm_eye_pressed)
	for input: LineEdit in [username_input, email_input, password_input, confirm_password_input]:
		if not input.text_submitted.is_connected(_on_text_submitted):
			input.text_submitted.connect(_on_text_submitted)
	var auth := _auth_service()
	if auth == null:
		_show_error("AuthService is niet beschikbaar.")
		return
	if not auth.login_finished.is_connected(_on_login_finished):
		auth.login_finished.connect(_on_login_finished)
	if not auth.signup_finished.is_connected(_on_signup_finished):
		auth.signup_finished.connect(_on_signup_finished)

func _try_continue_session() -> void:
	var session := _session_manager()
	if session == null:
		return
	session.load_session()
	if session.is_logged_in():
		_go_to_main_menu.call_deferred()

func _apply_initial_state() -> void:
	loading_indicator.visible = false
	loading_indicator.value = 0
	password_input.secret = true
	confirm_password_input.secret = true
	_set_controls_enabled(true)
	_set_mode(AuthMode.LOGIN, false)

func _set_mode(mode: AuthMode, show_help: bool = false) -> void:
	_mode = mode
	var registering := _mode == AuthMode.REGISTER
	username_input.visible = registering
	confirm_password_input.visible = registering
	confirm_eye_button.visible = registering
	login_username_mask.visible = not registering
	login_confirm_mask.visible = not registering
	register_button.tooltip_text = "Account maken" if registering else "Registratiemodus openen"
	login_button.tooltip_text = "Terug naar inloggen" if registering else "Inloggen"
	if show_help:
		_show_info(
			"Registreren: vul alle velden in." if registering
			else "Inloggen: vul je e-mailadres en wachtwoord in."
		)
	else:
		_set_status("", Color.WHITE)
	if registering:
		username_input.grab_focus()
	else:
		email_input.grab_focus()

func _toggle_password_visibility(input: LineEdit) -> void:
	input.secret = not input.secret

func _on_password_eye_pressed() -> void:
	_toggle_password_visibility(password_input)

func _on_confirm_eye_pressed() -> void:
	_toggle_password_visibility(confirm_password_input)

func _on_text_submitted(_text: String) -> void:
	if _is_loading:
		return
	if _mode == AuthMode.REGISTER:
		_submit_registration()
	else:
		_submit_login()

func _start_request(action: String, text: String) -> void:
	_is_loading = true
	_pending_action = action
	_timeout_left = REQUEST_TIMEOUT
	loading_indicator.visible = true
	loading_indicator.value = 10
	_set_status(text, Color(1.0, 0.78, 0.28))
	_set_controls_enabled(false)

func _finish_request(success: bool, text: String) -> void:
	_is_loading = false
	_pending_action = ""
	loading_indicator.visible = false
	loading_indicator.value = 0
	_set_status(text, Color(0.44, 1.0, 0.66) if success else Color(1.0, 0.38, 0.38))
	_set_controls_enabled(true)

func _set_controls_enabled(enabled: bool) -> void:
	username_input.editable = enabled
	email_input.editable = enabled
	password_input.editable = enabled
	confirm_password_input.editable = enabled
	register_button.disabled = not enabled
	login_button.disabled = not enabled
	password_eye_button.disabled = not enabled
	confirm_eye_button.disabled = not enabled

func _show_error(text: String) -> void:
	_set_status(text, Color(1.0, 0.38, 0.38))

func _show_info(text: String) -> void:
	_set_status(text, Color(0.78, 0.88, 1.0))

func _set_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	status_backdrop.visible = not text.is_empty()

func _is_valid_email(email: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")
	return regex.search(email) != null

func _friendly_error(message: String) -> String:
	var lower := message.to_lower()
	if lower.contains("invalid login") or lower.contains("invalid credentials") or lower.contains("invalid_credentials"):
		return "E-mailadres of wachtwoord klopt niet."
	if lower.contains("email not confirmed"):
		return "Bevestig eerst je e-mailadres en probeer daarna opnieuw."
	if lower.contains("already registered") or lower.contains("user_already_exists"):
		return "Er bestaat al een account met dit e-mailadres."
	if lower.contains("rate") or lower.contains("too many"):
		return "Te veel aanvragen. Wacht even en probeer het opnieuw."
	if lower.contains("signup") and lower.contains("disabled"):
		return "Nieuwe accounts zijn momenteel uitgeschakeld."
	if lower.contains("weak_password") or lower.contains("password should"):
		return "Kies een sterker wachtwoord van minimaal 8 tekens."
	if lower.contains("invalid email") or lower.contains("email_address_invalid"):
		return "Controleer je e-mailadres."
	if lower.contains("network") or lower.contains("timeout") or lower.contains("connection"):
		return "Netwerkfout. Controleer je verbinding en probeer opnieuw."
	return "Er ging iets mis. Probeer het opnieuw."

func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _ensure_main_menu_scene() -> void:
	if ResourceLoader.exists(MAIN_MENU_SCENE):
		return
	if ResourceLoader.exists("res://scenes/menus/MainMenu.tscn"):
		return
	push_warning("main_menu.tscn ontbreekt. Maak res://scenes/menus/main_menu.tscn aan of pas MAIN_MENU_SCENE aan.")

func _auth_service() -> Node:
	return get_node_or_null("/root/AuthService")

func _session_manager() -> Node:
	return get_node_or_null("/root/SessionManager")
