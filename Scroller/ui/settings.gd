extends Control

onready var tween = $List/Tween

func display():
	show()
	for i in $List.get_child_count():
		var child = $List.get_child(i)
		if child is Control:
			tween.interpolate_property(child, "rect_scale",
				Vector2(0, 1), Vector2.ONE, .1 + .1 * i,
				Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
			tween.start()

func _on_Fps_toggled(button_pressed):
	G.vars.setting.showfps = button_pressed

func _on_Volume_value_changed(value):
	G.vars.setting.volume = value
	G.sfx.adjust_sound()

func _on_Restart_pressed():
	G.game.restart()

func _on_Exit_pressed():
	G.game.end_game()
