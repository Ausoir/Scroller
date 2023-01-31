extends Node


func run(p):
	if p == null:
		return
	if p == "hint begin":
		show_hint("hint_begin")
	elif p == "hint kill":
		show_hint("hint_pickup")

func show_hint(p):
	if OS.get_name() in ["Android", "BlackBerry 10", "iOS"]:
		G.you.host.dat.dialog += G.data.dialog_data.get(p + "_touch")
	else:
		G.you.host.dat.dialog += G.data.dialog_data.get(p)
	G.you.host.action.has_dialog = true
