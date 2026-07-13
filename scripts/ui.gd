extends CanvasLayer

func set_role(hider: bool):
    $Margin/VBox/Role.text = "ROL: HIDER" if hider else "ROL: SEEKER"

func show_message(text: String):
    $Message.text = text
    $MessageTimer.start()

func _on_message_timer_timeout():
    $Message.text = ""
