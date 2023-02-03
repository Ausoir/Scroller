extends Node


func run(p):
	if p == null:
		return
	if p == "hint begin":
		show_hint("hint_begin")
	elif p == "hint kill":
		show_hint("hint_kill")

func show_hint(p):
	if p != null:
		var touch_ver = G.data.dialog_data.get(p + " touch")
		if touch_ver != null and OS.get_name() in ["Android", "BlackBerry 10", "iOS"]:
			G.you.host.dat.dialog += touch_ver
		else:
			G.you.host.dat.dialog += G.data.dialog_data.get(p)
		G.you.host.action.has_dialog = true
