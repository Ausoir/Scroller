extends "res://entity/pilot.gd"

onready var n_movement = $Movement

var view_dirty = 0
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
	if G.rng.ir(0, G.world.team[2].size()) != -1:
		G.display_damage("LEVEL UP", host.pos, Color.blueviolet, 1, 150)

func on_die():
	var unit = G.factory.make_unit("player", G.world.get_spawn_point())
	unit.possess(self)

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
		if Input.is_action_just_released("touch"):
			touch_events.clear()
			n_movement.hide()
			drag_position = Vector2.ZERO
			host.action.next_action = null
		elif Input.is_action_just_pressed("touch"):
			touch_position = event.position
			if host.action.delay == 0:
				n_movement.show()
				n_movement.position = event.position
			last_touch_time = 0

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
		elif Input.is_action_pressed("touch"):
			var action = diff_to_dir(drag_position.x, drag_position.y)
			if action != null:
				host.action.next_action = action

func get_face():
	return G.get_face(host.position.x, get_mouse().x)

func diff_to_dir(diffx, diffy):
	if abs(diffx) > abs(diffy):
		if diffx < 0:
			return ["walk", -1]
		elif diffx > 0:
			return ["walk", 1]
	elif diffy < 0:
		return ["jump", 2]
	elif diffy > 0:
		return ["down"]

func on_turn():
	perceive()
	var moved = G.camera.prev_pos != host.pos
	if moved or view_dirty > 0:
		if moved and host.delay == 0:
			pickup()
			if host.pos.x == G.world.size.x-1:
				G.game.travel("test")
				return
		view_dirty -= 1
		G.camera.start_process()
		G.world.turn.process_light()
		G.camera.prev_pos = host.pos
		make_noise(1)

func perceive():
	var foe_list = G.world.team[2]
	var foe_list_size = foe_list.size()
	for _i in range(min(28, foe_list_size)):
		if perceive_idx >= foe_list_size:
			perceive_idx = 0
		var foe = foe_list[perceive_idx]
		perceive_idx += 1
		if is_instance_valid(foe):
			var distx = abs(host.pos.x - foe.pos.x)
			var disty = abs(host.pos.y - foe.pos.y)
			if distx + disty*3 <= 6:
				_i += 4
				if host.pos.get_beam_to(foe.pos, 1)[1] == foe.pos:
					foe.pilot.engage(host)
			elif distx + disty <= noise:
				foe.pilot.hear(host.pos)
	noise = 0

func remove():
	pass

func make_noise(p):
	noise = max(p, noise)

func pickup():
	for i in range(host.pos.items.size()-1, -1, -1):
		var item = host.pos.items[i]
		if item.get_type() == 1 and item.dat.name == "skill":
			var skills = G.you.host.dat.get("skills", [])
			var level = G.you.host.dat.get("level", 1)
			if level > skills.size():
				skills.append(item.dat.get("skill"))
				item.animation.play("pickup")
				return

func unserialize():
	var player_pos = G.world.get_spawn_point()
	var player_unit = G.factory.make_unit("player", player_pos, G.vars.load_data)
	player_unit.possess(self)
	if G.camera.set_sight():
		G.camera.start_process()
