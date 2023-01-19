var host
var on_finish = null
var current_action = null
var current_action_fn = "idle"
var last_action = null
var next_action = null
var delay = 0
var move_delay = 2
var skills = []
var skills_spent = []
var commands = []
var turns = 0

func _init(p):
	host = p

func on_turn():
	if delay > 0:
		delay -= 1
	elif delay == 0:
		if next_action != null:
			set_action(next_action)
			next_action = null
		elif turns > 12:
			focus()
			turns = 0
	turns += 1
	process_commands()

func set_action(params):
	turns = 0
	commands = []
	if delay != 0:
		on_finish = null
	current_action = params.pop_front()
	current_action_fn = funcref(self, current_action)
	if on_finish:
		var fn = on_finish  # prevent recursion
		on_finish = null
		if funcref(self, fn).call_func():
			return true
	current_action_fn.call_funcv(params)
	last_action = current_action

func on_animation_done(p):
	if delay == 0 and !p.begins_with("idle"):
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
		if skill != null and skill.type == moveset:
			commands = skill.get("run", []).duplicate()
			delay = skill.get("delay", 1)
			if dir != 0:
				host.face(dir)
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

func land():
	host.set_animation("land")
	delay = 4
	if host.fall_height > 2:
		host.pos.set_state("fall", host.pos.x)

func attack(dir):
	for item in host.pos.items:
		if is_instance_valid(item):
			if item.get_type() == 2 and item.team != host.team:
				if pop_moveset("grab"):
					return
	var targetpos = host.pos.get_neighbor(host.dir, 0)
	if !targetpos.is_col(2):
		if pop_moveset("lunge", dir):
			return
	if !pop_moveset("melee", dir):
		focus()
	else:
		stand()

func focus():
	if !skills_spent.empty() and !host.animation.get_assigned_animation().begins_with("focus"):
		host.set_animation("focus_" + str(G.rng.ir(1, 3)))

func hit(type):
	if host.col & 2 == 0:
		return
	if delay == 0 and type == "light" and !host.injury:
		host.set_animation("block_" + str(G.rng.ir(1, 2)))
		delay = 4
	else:
		host.set_col(0)
		if !pop_moveset("dodge"):
			if !host.injury:
				host.set_animation("ko_1")
				host.injury = true
				commands = [[10, "col", 2]]
				delay = 12
			else:
				host.set_animation("ko_" + str(G.rng.ir(2, 3)))
				commands = [[14, "do", "fadeout"],[32, "die"]]
				delay = -1

func down():
	if host.beneath.is_col(4):
		host.position_speed = 1
		var targetpos = host.pos.get_neighbor(0, 1)
		host.relocate(targetpos)
		host.set_animation("climb", 1.5)
		delay = 3

func jump(dir):
	host.face(dir)
	if host.pos.is_col(4):
		var targetpos = host.pos.get_neighbor(0, -1)
		if !targetpos.is_col(4):
			host.position_speed = -1
			host.set_animation("pullup")
			delay = 6
		else:
			host.position_speed = 1
			host.set_animation("climb", 1.5)
		host.relocate(targetpos)
		delay = 4
	else:
		host.set_animation("jump")
		delay = 4

func jump_1():
	host.position_speed = -3
	var targetpos = host.pos.get_neighbor(host.dir, -1)
	if !targetpos.is_col(10):
		host.relocate(targetpos)
	delay = 4

func walk(dir):
	host.face(dir)
	var targetpos = host.pos.get_neighbor(host.dir, 0)
	if targetpos.is_col(2):
		for i in targetpos.get_items_by_type(2):
			if i.team != host.team:
				attack(dir)
				return
	if !targetpos.is_col(host.col_mask):
		host.position_speed = 4
		if host.injury:
			host.set_animation("walk_injured", 1)
			delay = 3
		else:
			host.set_animation("walk", 1.5)
			delay = 2
		host.relocate(targetpos)
	else:
		stand()

func die():
	host.set_animation("fadeout")
	delay = -1

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
		host.pos.get_neighbor(host.dir, 0).set_state(cmd[2], host.pos.x)
	elif cmd[1] == "grab":
		host.pos.set_state("grab", host.pos.x)
	elif cmd[1] == "toward":
		host.position_speed = cmd[3]
		var to = host.pos.get_neighbor(host.dir * cmd[2], 0)
		if !to.is_col(10):
			host.relocate(to)
	elif cmd[1] == "col":
		host.set_col(int(cmd[2]))
	elif cmd[1] == "refresh":
		refresh_skills(cmd[2])
	elif cmd[1] == "pop":
		skills_spent.append(cmd[2])
		skills.erase(cmd[2])
	elif cmd[1] == "die":
		host.die()
	return true
