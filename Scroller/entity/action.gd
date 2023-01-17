const LUNGE = [["kick", 8], ["lunge", 12]]
const MELEE = [["punch", 5], ["flurry", 6], ["knockdown", 7]]
var host
var on_finish = null
var current_action = null
var current_action_fn = "idle"
var last_action = null
var next_action = null
var delay = 0
var move_delay = 2
var idle_frame = 0
var skills = []

func _init(p):
	host = p

func on_turn():
	if delay > 0:
		delay -= 1
	elif delay == 0:
		if next_action != null:
			set_action(next_action)
			next_action = null
		else:
			stand()

func set_action(params):
	idle_frame = 0
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

func set_moveset(moveset):
	for i in moveset:
		var skill = i[0]
		if skill in skills:
			skills.erase(skill)
			host.set_animation(skill)
			delay = i[1]
			return true
	stand()
	return false

func refresh_skills():
	skills = host.skills.duplicate()

func stand():
	host.set_animation("stand")

func focus():
	host.set_animation("focus1")
	delay = 18
	refresh_skills()

func attack(dir):
	host.face(dir)
	var targetpos = host.pos.get_neighbor(host.dir, 0)
	if !targetpos.is_col(host.col_mask):
		if set_moveset(LUNGE):
			host.position_speed = 4
			host.relocate(targetpos)
			host.pos.get_neighbor(host.dir, 0).set_state("bash", host.pos.x)
	else:
		if set_moveset(MELEE):
			targetpos.set_state("hit", host.pos.x)

func fall():
	host.set_animation("fall")
	delay = 2

func hit():
	host.set_animation("hit")
	delay = 2

func knockout():
	host.set_animation("knockout")
	delay = 40

func knockback():
	host.set_animation("knockback")
	delay = 40

func jump():
	host.position_speed = 16
	host.set_animation("jump", 1)
	delay = 4

func jump_1():
	host.position_speed = 16
	var targetpos = host.pos.get_neighbor(host.dir, -1)
	host.relocate(targetpos)
	delay = 4

func lunge():
	var targetpos = host.pos.get_neighbor(host.dir, 0)
	host.set_animation("lunge")
	host.relocate(targetpos)
	delay = 16

func walk(dir):
	host.face(dir)
	var targetpos = host.pos.get_neighbor(host.dir, 0)
	for item in targetpos.items:
		if is_instance_valid(item):
			if item.get_type() == 2:
				if item.action.delay == 0 and item.team == host.team:
					item.relocate(host.pos)
	if !targetpos.is_col(host.col_mask):
		host.position_speed = 4
		host.set_animation("walk", 2)
		host.relocate(targetpos)
		delay = 2
	else:
		host.set_animation("stand")

func ability(idx, at):
	if idx < 0:
		return G.fx.do(G.data.ability_data.get("pickup"), host, at)
	elif idx < host.abilities.size():
		host.face_toward(at)
		return G.fx.do(host.abilities[idx], host, at)
