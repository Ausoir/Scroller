extends "res://entity/pilot.gd"

onready var n_movement = $Movement

var view_dirty = 0
var unhandled_input = false
var on_point
var touch_position = Vector2()
var drag_position = Vector2()
var last_touch_time = 0
var last_drag_dist = 0
var touch_events = {}
var noise = 0
var perceive_idx = 0

func on_assign():
	.on_assign()
	host.team = 1
	G.camera.target = host
	G.camera.prev_pos = host.pos
	G.camera.set_process(true)

func on_kill(_victim):
	var money = G.rng.ir(0, _victim.dat.get("value", 0))
	if money > 0:
		make_money(money)

func on_die():
	var unit = G.factory.make_unit("player", G.world.get_spawn_point())
	unit.possess(self)

func make_money(p):
	G.vars.money = G.vars.money+p
	if p >= 0:
		G.display_damage("+"+G.L.str_money(p), host.pos, Color.gold, 1, 250)
	else:
		G.display_damage("-"+G.L.str_money(p), host.pos, Color.indigo, 1, 250)

func get_mouse():
	var screen_mouse = G.ui.mouse_pos
	screen_mouse -= G.ui.screen_size / 2
	return Vector2(screen_mouse.x*G.camera.zoom.x + G.camera.position.x,
				screen_mouse.y*G.camera.zoom.y + G.camera.position.y)

func zoom(new_zoom):
	new_zoom = clamp(G.camera.zoom.x * new_zoom, .5, 2)
	G.camera.zoom = Vector2.ONE * new_zoom

func _on_input(event: InputEvent):
	if event is InputEventScreenDrag:
		if unhandled_input:
			touch_events[event.index] = event
			if touch_events.size() == 2:
				var drag_distance = touch_events[0].position.distance_to(touch_events[1].position)
				if abs(drag_distance - last_drag_dist) > 10:
					var new_zoom = .95
					if drag_distance < last_drag_dist:
						new_zoom = 1.05
					zoom(new_zoom)
					last_drag_dist = drag_distance
			else:
				drag_position = event.position - touch_position
	elif event is InputEventMouseButton:
		if Input.is_action_just_released("use"):
			touch_events.clear()
			n_movement.hide()
			drag_position = Vector2.ZERO
			if unhandled_input:
				host.action.next_action = null
				unhandled_input = false
		elif Input.is_action_just_pressed("use"):
			unhandled_input = true
			touch_position = event.position
			if host.action.delay == 0:
				n_movement.show()
				n_movement.position = event.position
			last_touch_time = 0
		elif Input.is_action_just_pressed("zoom in"):
			zoom(.9)
		elif Input.is_action_just_pressed("zoom out"):
			zoom(1.1)

func _physics_process(_delta):
	last_touch_time += _delta
	if host.action.delay == 0:
		if Input.is_action_pressed("ui_up"):
			host.action.next_action = ["jump", host.dir]
		elif Input.is_action_pressed("ui_down"):
			host.action.next_action = ["down"]
		elif Input.is_action_pressed("ui_right"):
			host.action.next_action = ["walk", 1]
		elif Input.is_action_pressed("ui_left"):
			host.action.next_action = ["walk", -1]
		elif Input.is_action_pressed("use"):
			host.action.next_action = ["attack", get_face()]

func get_face():
	return G.get_face(host.position.x, get_mouse().x)

func on_turn():
	perceive()
	if G.camera.prev_pos != host.pos or view_dirty > 0:
		view_dirty -= 1
		G.camera.start_process()
		G.world.turn.process_light()
		G.camera.prev_pos = host.pos
		make_noise(1)

func interact(tile):
	if !G.ui.on:
		for item in tile.items:
			if item != host:
				var oninteract = item.dat.get("oninteract")
				if oninteract != null:
					G.cmds(oninteract, item.dat, host)
					return true

func perceive():
	var foe_list = G.world.team[2]
	var foe_list_size = foe_list.size()
	for _i in range(min(28, foe_list_size)):
		if perceive_idx >= foe_list_size:
			perceive_idx = 0
		var foe = foe_list[perceive_idx]
		perceive_idx += 1
		if is_instance_valid(foe):
			var dist = abs(host.pos.x - foe.pos.x) + abs(host.pos.y - foe.pos.y)*3
			if dist <= 6:
				_i += 4
				if host.pos.get_beam_to(foe.pos, 1)[1] == foe.pos:
					if dist <= max(1, G.camera.get_visible_distance(host.pos.light, 6)):
						foe.pilot.engage(host)
				elif dist <= noise:
					foe.pilot.hear(host.pos)
	noise = 0

func remove():
	pass

func make_noise(p):
	noise = max(p, noise)

func unserialize():
	var player_pos = G.world.get_spawn_point()
	var player_unit = G.factory.make_unit("player", player_pos)
	player_unit.possess(self)
	make_money(0)
	if G.camera.set_sight():
		G.camera.start_process()

func check_brightness(p):
	if p == null:
		return true
	var brightness = host.pos.light
	if "nocturnal" in host.tags:
		brightness += 1
	if brightness < 3:
		if p:
			G.msg(["Too dark!"])
			return false
	elif !p:
		G.msg(["Too bright!"])
		return false
	return true
