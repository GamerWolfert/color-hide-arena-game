extends Node

@export var preparation_time := 20
@export var round_time := 120
var time_left := 20
var preparing := true

func _ready():
    $Timer.start()
    update_ui()

func _on_timer_timeout():
    time_left -= 1
    if time_left <= 0:
        if preparing:
            preparing = false
            time_left = round_time
            $"../UI".show_message("Zoekfase gestart")
        else:
            time_left = round_time
            $"../UI".show_message("Nieuwe ronde")
    update_ui()

func update_ui():
    var m := int(time_left / 60)
    var s := time_left % 60
    $"../UI/Margin/VBox/Timer".text = ("%s %02d:%02d" % ["VOORBEREIDING" if preparing else "RONDE", m, s])
