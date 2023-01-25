extends Node

const Task = preload("res://entity/task.gd")
var host
var default = null
var move = null
var attack = null
var route = null
var task = null
var priority = 5
var frame = 0
var lifetime = 500
var alert = 0
var is_humanoid = false
var has_night_vision = false
var closest_enemy

func set_ai(args):
	if args.empty():
		default = Task.Wander.new()
	elif default == null or default.get_class() != args[0]:
		default = str_to_task(args[0]).new()
	if args.size() < 2:
		if move == null:
			move = Task.Pathing.new()
	elif move == null or move.get_class() != args[1]:
		move = str_to_task(args[1]).new()
	if args.size() < 3:
		if attack == null:
			attack = Task.Attack.new()
	elif attack == null or attack.get_class() != args[2]:
		attack = str_to_task(args[2]).new()
	default.pilot = self
	move.pilot = self
	attack.pilot = self
	set_task(default)

func str_to_task(p):
	if p == "guard":
		return Task.Guard
	elif p == "wander":
		return Task.Wander
	elif p == "follow":
		return Task.Follow
	elif p == "path":
		return Task.Pathing
	elif p == "attack":
		return Task.Attack
	elif p == "talk":
		return Task.Talk
	elif p == "idle":
		return Task.Idle

func on_turn():
	if host.action.delay == 0:
		if task.on_turn():
			task.perform()

func set_task(p):
	p.on_set()
	task = p

func on_hit(hitter):
	if is_instance_valid(hitter) and hitter != host:
		if task.target != hitter and hitter.team == host.team*-1:
			set_task(attack)
			task.target = hitter

func on_die():
	G.you.on_kill(host)

func hear(at):
	if priority > 3:
		if !("deaf" in host.tags):
			if at.distance_to(host.pos) >= 1:
				var seentile = host.pos.get_beam_to(at, 1)[1]
				if seentile == at:
					for i in at.items:
						if host.team == i.team * -1:
							engage(i)
							return
				else:
					move.target = at
					set_task(move)

func engage(p):
	if p != null and priority > 1:
		set_task(attack)
		task.target = p

func remove():
	queue_free()

func on_change(_p):
	pass

func on_assign():
	pass

func unassign():
	if host != null:
		host.pilot = null
		host.possess()
		host = null
