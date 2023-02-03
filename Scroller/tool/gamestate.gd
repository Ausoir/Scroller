extends Node

var player_name = "Player"

func travel(args, sound=null):
	if args != null:
		if sound != null:
			G.sfx.play(sound, G.you.host.pos)
		G.get_tree().set_pause(true)
		G.you.host.pos.remove_item(G.you.host)
		G.world.create(args)
		G.you.host.relocate(G.world.get_spawn_point(), true)
		G.you.host.action.delay = 8
		G.camera.prev_pos = G.you.host.pos
		G.camera.start_process()
		G.get_tree().set_pause(false)
		G.ui.fadein()
		if G.world.mapdata.get("save"):
			save_game()

func end_game():
	G.ui.clear()
	G.get_tree().set_pause(true)
	G.get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)

func abandon_game():
	G.vars["dead"] = true
	G.get_tree().set_pause(true)
	restart()

func restart():
	clean_up()
	G.get_tree().set_pause(false)
	G.get_tree().change_scene_to(load("res://Start.tscn"))

func clean_up():
	G.get_tree().set_pause(true)
	var root = G.get_tree().get_root()
	for i in root.get_children():
		if i != self and i != G:
			i.queue_free()
			root.remove_child(i)
	for i in G.get_children():
		i.queue_free()
		G.remove_child(i)
	G._ready()
	G.get_tree().set_pause(false)

func start_game():
	load_game()
	G.time.set_process(true)
	G.get_tree().set_pause(true)
	G.time.reset()
	G.get_tree().change_scene_to(load('res://world/World.tscn'))
	G.get_tree().set_pause(false)

func save_game(end=false):
	if G.you.host != null and !G.vars.get("dead", false):
		var tile = G.you.host.pos
		tile.remove_item(G.you.host)
		var save_game = File.new()
		save_game.open("user://savegame.save", File.WRITE)
		if end:
			G.camera.set_process(false)
			G.camera.target = null
		else:
			G.you.host.relocate(tile, true)
		if G.you.host != null:
			G.vars.map = G.world.mapname
			G.vars.seed = G.rng.init_seed
			save_game.store_line(to_json(G.vars))
			save_game.store_line(to_json(G.you.host.dat))
		save_game.close()

func load_game():
	var save_game = File.new()
	var line
	save_game.open("user://savegame.save", File.READ)
	var is_open = save_game.is_open()
	if is_open:
		line = save_game.get_line()
		if !line.empty():
			G.vars = parse_json(line)
	if !is_open or line.empty():
		save_game.close()
		save_game = File.new()
		save_game.open("res://assets/template.save", File.READ)
		line = save_game.get_line()
		G.vars = parse_json(line)
	G.vars["load_data"] = parse_json(save_game.get_line())
	save_game.close()

func load_settings():
	var save_game = File.new()
	var line
	save_game.open("user://settings.save", File.READ)
	var is_open = save_game.is_open()
	if is_open:
		line = save_game.get_line()
		if !line.empty():
			G.settings = parse_json(line)
	G.ui.menu_settings.update_changes()

func save_settings():
	var save_game = File.new()
	save_game.open("user://settings.save", File.WRITE)
	save_game.store_line(to_json(G.settings))
	save_game.close()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit() # default behavior
#	elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
#		save_game()
