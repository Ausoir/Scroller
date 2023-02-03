var host
var current_action = null
var current_action_fn = "idle"
var next_action = null
var delay = 0
var move_delay = 2
var skills = []
var skills_spent = []
var commands = []
var turns = 0
var focusing = false
var has_dialog = true
var barrier = 0

func _init(p):
	host = p

func on_turn():
	if delay > 0:
		delay -= 1
	elif delay == 0:
		if next_action != null:
			set_action(next_action)
			next_action = null
		elif has_dialog and !focusing:
			talk()
	barrier = max(0, barrier - 1)
	turns += 1
	process_commands()

func set_action(params):
	turns = 0
	commands = []
	current_action = params.pop_front()
	current_action_fn = funcref(self, current_action)
	current_action_fn.call_funcv(params)
	current_action = null

func on_animation_done(_p):
	focusing = false
	if delay == 0:
		stand()

func has_moveset(moveset):
	for i in skills:
		var skill = G.data.skill_data.get(i)
		if skill != null and skill.type == moveset:
			return true
	return false

func pop_moveset(moveset, dir=0):
	for i in skills:
		var skill = G.data.skill_data.get(i)
		if skill != null and skill.type == moveset and is_req_met(skill.get("condition")):
			commands = skill.get("run", []).duplicate()
			delay = skill.get("delay", 1)
			if dir != 0:
				host.face(dir)
			host.chat.say(skill.name.capitalize() + "!")
			return true

func refresh_skills(p=null):
	if p == null:
		skills = []
		skills_spent = []
		for i in host.dat.get("skills", []):
			skills.append(i)
	else:
		for i in skills_spent.duplicate():
			if G.data.skill_data.get(i).type == p:
				skills.append(i)
				skills_spent.erase(i)

func stand():
	host.set_col(2)
	if host.injury:
		host.set_animation("idle_injured")
	else:
		host.set_animation("idle_1")

func land(height):
	host.set_animation("land")
	delay = 5
	G.sfx.play("land", host.pos)
	if height > 2:
		var foe = host.pos.get_items_by_team(host.team * -1).pop_front()
		if foe != null and pop_moveset("plunge", 0):
			host.pos.set_state("heavy", host.pos.x, host.team)
		else:
			host.hit("fall", host.pos.x)

func lunge(dir):
	var targetpos = host.pos.get_neighbor(host.dir, 0)
	if !targetpos.is_col(10):
		if pop_moveset("lunge", dir):
			return true

func grab():
	var foe = host.pos.get_items_by_team(host.team * -1).pop_front()
	if foe != null and pop_moveset("grab"):
		return true

func attack(dir):
	if grab():
		return
	if lunge(dir):
		return
	if !pop_moveset("melee", dir):
		focus()

func focus():
	if !focusing:
		if !skills_spent.empty():
			focusing = true
			host.set_animation("focus_" + str(G.rng.ir(1, 3)))
		elif pop_moveset("focus"):
			focusing = true
			return

func hit(type):
	if host.col & 2 == 0:
		return
	if type == "breaker":
		G.sfx.play("breaker", host.pos)
		G.you.make_noise(6)
		host.set_col(0)
		host.chat.say_personalized(G.data.dialog_data.get("hit"))
		host.set_animation("ko_" + str(G.rng.ir(1, 3)))
		commands = [[10, "col", 2]]
		delay = 12
	elif (barrier > 0 and type != "fall") or (delay == 0 and type == "light" and !focusing):
		G.sfx.play("block", host.pos)
		G.you.make_noise(3)
		host.set_animation("block_" + str(G.rng.ir(1, 2)))
		delay = 4
		host.chat.say_personalized(G.data.dialog_data.get("block"))
	else:
		G.you.make_noise(6)
		host.set_col(0)
		if !pop_moveset("dodge"):
			if type == "heavy":
				var to = host.pos.get_neighbor(-host.dir, 0)
				if !to.is_col(8):
					host.relocate(to)
			if !host.injury:
				G.sfx.play("hit", host.pos)
				host.chat.say_personalized(G.data.dialog_data.get("hit"))
				host.set_animation("ko_1")
				host.injury = true
				refresh_skills()
				commands = [[10, "col", 2]]
				delay = 12
				barrier = 16
			else:
				G.sfx.play("die", host.pos)
				if host.chat.lifetime < 5:
					host.chat.say_personalized(G.data.dialog_data.get("die"))
				host.team = 0
				host.set_animation("ko_" + str(G.rng.ir(2, 3)))
				commands = [[10, "do", "fadeout"],[11, "loot"],[28, "die"]]
				delay = -1
		else:
			G.sfx.play("dodge", host.pos)
			host.chat.say_personalized(G.data.dialog_data.get("dodge"))

func down():
	if !grab():
		if host.beneath.is_col(4):
			host.position_speed = 1
			var targetpos = host.pos.get_neighbor(0, 1)
			host.relocate(targetpos)
			host.set_animation("climb", 1.5)
			G.sfx.play("climb", host.pos)
			delay = 3
		else:
			attack(host.dir)

func jump(dir):
	host.face(dir)
	if host.pos.is_col(4):
		var targetpos = host.pos.get_neighbor(0, -1)
		if !targetpos.is_col(8):
			if !targetpos.is_col(4):
				G.sfx.play("pullup", host.pos)
				host.position_speed = -1
				host.set_animation("pullup")
				delay = 6
			else:
				G.sfx.play("climb", host.pos)
				host.position_speed = 1
				host.set_animation("climb", 1.5)
				delay = 3
			host.relocate(targetpos)
	else:
		host.set_animation("jump")
		delay = 4

func jump_1():
	host.position_speed = -3
	var targetpos = host.pos.get_neighbor(host.dir, -1)
	if !targetpos.is_col(8):
		host.relocate(targetpos)
	G.sfx.play("jumped", host.pos)
	delay = 6

func walk(dir):
	host.face(dir)
	var targetpos = host.pos.get_neighbor(host.dir, 0)
	if targetpos.is_col(2) and !targetpos.get_items_by_team(host.team * -1).empty():
		attack(dir)
	elif !targetpos.is_col(host.col_mask):
		host.position_speed = 4
		if host.injury:
			host.set_animation("walk_injured", 1)
			delay = 3
		else:
			host.set_animation("walk", 1.5)
			delay = 2
		G.sfx.play(host.pos.get_neighbor(0, 1).step_sound, host.pos)
		host.relocate(targetpos)
	else:
		stand()

func talk():
	if host.chat.lifetime == 0:
		var text = host.dat.get("dialog", []).pop_front()
		if text != null:
			if text.begins_with("#"):
				G.event.show_hint(text.substr(1))
			else:
				host.chat.say(text)
				host.set_animation("talk")
		else:
			has_dialog = false

func process_commands():
	if commands.empty():
		return false
	var cmd = commands[0]
	if turns < cmd[0]:
		return false
	commands.pop_front()
	if cmd[1] == "do":
		host.set_animation(cmd[2])
	elif cmd[1] == "dod":
		host.set_animation(cmd[2])
		delay = int(host.animation.get_current_animation_length() * 6.67)
	elif cmd[1] == "attack":
		G.sfx.play("swing", host.pos)
		if cmd.size() > 3:
			host.pos.get_neighbor(host.dir, 0).set_state(cmd[2], host.pos.x, cmd[3])
		else:
			host.pos.get_neighbor(host.dir, 0).set_state(cmd[2], host.pos.x)
	elif cmd[1] == "grab":
		host.pos.set_state("grab", host.pos.x, host.team)
	elif cmd[1] == "toward":
		host.position_speed = cmd[3]
		var to
		if cmd[2] == 2:
			to = host.pos.get_neighbor(0, 1)
		elif cmd[2] == -2:
			to = host.pos.get_neighbor(0, -1)
		else:
			to = host.pos.get_neighbor(host.dir * cmd[2], 0)
		if !to.is_col(10):
			host.relocate(to)
	elif cmd[1] == "col":
		host.set_col(int(cmd[2]))
	elif cmd[1] == "refresh":
		refresh_skills(cmd[2])
	elif cmd[1] == "pop":
		skills_spent.append(cmd[2])
		skills.erase(cmd[2])
	elif cmd[1] == "barrier":
		barrier = int(cmd[2])
	elif cmd[1] == "die":
		host.die()
	elif cmd[1] == "injury":
		host.injury = cmd[2]
	elif cmd[1] == "say":
		host.chat.say(cmd[2])
	elif cmd[1] == "sfx":
		G.sfx.play(cmd[2], host.pos)
	elif cmd[1] == "loot":
		host.drop_loot()
	return true

func is_req_met(p):
	if p != null:
		for i in p:
			if i == "unhurt" and host.injury:
				return false
			elif i == "hurt" and !host.injury:
				return false
	return true
