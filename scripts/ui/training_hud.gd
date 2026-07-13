extends CanvasLayer

@onready var role_label: Label = $Root/TopLeft/VBox/Role
@onready var phase_label: Label = $Root/TopLeft/VBox/Phase
@onready var timer_label: Label = $Root/TopLeft/VBox/Timer
@onready var camo_label: Label = $Root/TopLeft/VBox/Camo
@onready var part_label: Label = $Root/TopLeft/VBox/Part
@onready var pose_label: Label = $Root/TopLeft/VBox/Pose
@onready var energy_label: Label = $Root/TopLeft/VBox/Energy
@onready var hiders_label: Label = $Root/TopLeft/VBox/Hiders
@onready var message_label: Label = $Root/Message
@onready var pulse: ColorRect = $Root/Crosshair/Pulse
@onready var message_timer: Timer = $MessageTimer
@onready var pulse_timer: Timer = $PulseTimer

func _ready() -> void:
	message_timer.timeout.connect(func(): message_label.text = "")
	pulse_timer.timeout.connect(func(): pulse.visible = false)

func bind_player(player: Node) -> void:
	if player.has_signal("role_changed"):
		player.role_changed.connect(_on_role_changed)
	if player.has_signal("color_sampled"):
		player.color_sampled.connect(func(_color): show_message("Kleur gekopieerd"))
	if player.has_signal("seeker_scanned"):
		player.seeker_scanned.connect(func(found, _target, energy): _on_scan(found, energy))
	if player.has_signal("camouflage_changed"):
		player.camouflage_changed.connect(_on_camouflage_changed)
	if player.has_signal("scanner_fired"):
		player.scanner_fired.connect(_on_scanner_fired)
	if player.get("is_hider") != null:
		_on_role_changed(player.is_hider)

func bind_round_manager(round_manager: Node) -> void:
	round_manager.phase_changed.connect(_on_phase_changed)
	round_manager.timer_changed.connect(_on_timer_changed)
	round_manager.round_message.connect(show_message)
	round_manager.round_finished.connect(func(winner): show_message("%s wint de ronde" % winner))
	if round_manager.has_signal("hider_count_changed"):
		round_manager.hider_count_changed.connect(_on_hider_count_changed)

func show_message(text: String) -> void:
	message_label.text = text
	message_timer.start()

func _on_role_changed(is_hider: bool) -> void:
	role_label.text = "ROL: HIDER" if is_hider else "ROL: SEEKER"

func _on_phase_changed(phase_name: String, seconds_left: int) -> void:
	phase_label.text = "FASE: %s" % phase_name
	_on_timer_changed(seconds_left)

func _on_timer_changed(seconds_left: int) -> void:
	var minutes := int(seconds_left / 60)
	var seconds := seconds_left % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func _on_camouflage_changed(percent: float, selected_part: String, pose_name: String) -> void:
	camo_label.text = "CAMO: %d%%" % int(percent)
	part_label.text = "DEEL: %s" % selected_part
	pose_label.text = "POSE: %s" % pose_name

func _on_scan(found: bool, energy: float) -> void:
	energy_label.text = "ENERGIE: %d" % int(energy)
	show_message("Hider gevonden" if found else "Scan mis")

func _on_scanner_fired(hit: bool) -> void:
	pulse.color = Color(0.30, 1.0, 0.55, 0.48) if hit else Color(1.0, 0.35, 0.20, 0.45)
	pulse.visible = true
	pulse_timer.start()

func _on_hider_count_changed(remaining: int, total: int) -> void:
	hiders_label.text = "HIDERS: %d/%d" % [remaining, total]
