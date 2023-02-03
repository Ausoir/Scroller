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
	$List/Sounds/Sound.set_value(G.settings.get("sound", 50))
	$List/Fps.set_pressed(G.settings.get("showfps", false))

func _on_Fps_toggled(button_pressed):
	G.settings["showfps"] = button_pressed
	update_changes()
	G.game.save_settings()

func _on_Sound_value_changed(value):
	G.settings["sound"] = value
	update_changes()
	G.game.save_settings()

func _on_Restart_pressed():
	G.game.restart()

func _on_Exit_pressed():
	G.game.end_game()

func update_changes():
	if G.settings["showfps"]:
		G.ui.n_fps.show()
	else:
		G.ui.n_fps.hide()
	G.sfx.adjust_sound()
