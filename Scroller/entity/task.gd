class Idle:
	var target
	var pilot

	func perform():
		pass

	func on_set():
		pilot.priority = 5
		pilot.lifetime = 100

	func on_turn():
		if pilot.lifetime > 0:
			pilot.lifetime -= 1
		elif pilot.lifetime == 0:
			pilot.set_task(pilot.default)
			return false
		return true


class TileTask extends Idle:
	func on_turn():
		if .on_turn():
			if target == null:
				pilot.set_task(pilot.default)
				return false
			return true

class TargetTask extends Idle:
	func on_turn():
		if .on_turn():
			if target == null or !is_instance_valid(target):
				pilot.set_task(pilot.default)
				return false
			return true


class Pathing extends TileTask:
	class pathnode:
		var parent
		var pos
		var g = 0
		var h = 0
		var f = 0

		func _init(pparent, pnode):
			parent = pparent
			pos = pnode

		func set_h(destination):
			h = pos.difference_to(destination)

		func __str__():
			return pos.__str__()+'/'+str(f)
	var chase = 1
	var open = null
	var closed = []
	var closest = null
	var result = []
	var next_reset = 0
	var heuristic_threshold = 0
	var out_of_reach = false
	var fly = false

	func on_set():
		.on_set()
		out_of_reach = false

	func iterate(node):
		var index = 0
		for k in range(open.size()):
			var v = open[k]
			if v.f < node.f:
				index = k
				node = v
		open.pop_at(index)
		closed.append(node)
		var achieved = node.pos.difference_to(target)
		if achieved == 0:
			return node
		if achieved < closest.pos.difference_to(target):
			closest = node
		var options = node.pos.get_routes()
		for route in options:
			var pos = node.pos.get_neighbor(route.x, route.y)
			var new = pathnode.new(node, pos)
			new.g = node.g + 1
			new.set_h(target)
			new.f = new.h + new.g
			if new.h < heuristic_threshold:
				open.append(new)

	func check_loop(loop, pos):
		for i in loop:
			if i.pos == pos:
				return i

	func perform():
		if target == null or pilot.host.pos.difference_to(target) <= 1:
			return true
		if !result.empty():
			var pos = pilot.host.pos
			var to = result.pop_front()
			var dir = G.get_face(pilot.host.pos.x, to.x)
			if pos.y > to.y:
				pilot.host.action.next_action = ["jump", dir]
			elif pos.y < to.y and pos.x == to.x:
				pilot.host.action.next_action = ["down"]
			else:
				pilot.host.action.next_action = ["walk", dir]
			result = []

	func on_turn():
		if .on_turn():
			if result.empty():
				var diff = pilot.host.pos.difference_to(target)
				if diff > 1:
					out_of_reach = false
					var done = null
					if next_reset == 0:
						reset()
						next_reset = 1
					else:
						next_reset += 1
					for _times in range(11):
						if open:
							done = iterate(open[0])
							if done != null:
								break
						else:
							break
#					debug_trace()
					if done == null and next_reset > chase:
						out_of_reach = true
						done = closest
					if done:
						next_reset = 0
						result = [done.pos]
						while done.parent:
							done = done.parent
							if done.pos == pilot.host.pos:
								break
							result.insert(0, done.pos)
				elif diff == 1:
					result = [target]
			return true
	
	func debug_trace():
		for draw in open:
			G.make_particle("Hit", draw.pos)

	func reset():
		var dist = pilot.host.pos.distance_to(target)
		if dist > G.C:
			out_of_reach = true
		heuristic_threshold = dist * 2 + 2
		open = [pathnode.new(null, pilot.host.pos)]
		closed = []
		closest = open[0]


class Wander extends Idle:
	var dir

	func on_set():
		.on_set()
		pilot.lifetime = G.rng.ir(1, 50)
		pilot.priority = 4
		dir = G.rng.ir(-1, 1)

	func random_state():
		if dir == 0:
			pilot.host.action.next_action = ["stand"]
		else:
			var neighbor = pilot.host.pos.get_neighbor(dir, 0)
			if neighbor != pilot.host.pos and neighbor.is_land():
				pilot.host.action.next_action = ["walk", dir]
			else:
				dir *= -1

	func on_turn():
		if .on_turn():
			random_state()
			return true


class Attack extends TargetTask:
	func on_set():
		.on_set()
		pilot.lifetime = -1
		pilot.priority = 1

	func on_turn():
		if .on_turn():
			pilot.move.target = target.pos
			pilot.move.on_turn()
			return true

	func perform():
		if target != null:
			var diff = target.pos.difference_to(pilot.host.pos)
			if !pilot.host.animation.current_animation.begins_with("focus"):
				if diff == 0:
					pilot.host.action.next_action = ["attack", 0]
				elif diff == 1:
					if target.pos.x != pilot.host.pos.x:
						pilot.host.action.next_action = ["attack", G.get_face(pilot.host.pos.x, target.pos.x)]
					elif target.pos.y < pilot.host.pos.y:
						pilot.host.action.next_action = ["jump", G.get_face(pilot.host.pos.x, target.pos.x)]
					else:
						pilot.host.action.next_action = ["down"]
				else:
					pilot.move.target = target.pos
					pilot.move.perform()


class Follow extends TargetTask:
	func on_set():
		.on_set()
		pilot.priority = 3
		target = G.you.host

	func on_turn():
		if .on_turn():
			pilot.move.target = target.pos
			var temp = pilot.move.chase
			pilot.move.chase = 4
			pilot.move.on_turn()
			pilot.move.chase = temp
			return true

	func perform():
		pilot.move.target = target.pos
		pilot.move.perform()


class Guard extends Pathing:
	func on_set():
		.on_set()
		pilot.lifetime = 50
		target = null

	func on_turn():
		if target == null:
			var host_ab_pos = pilot.host.pos.get_coordinates()
			var guard = pilot.host.dat.get("guard")
			var tile
			if guard:
				var pos = guard.split(',')
				tile = pilot.host.pos.get_neighbor(int(pos[0]) - host_ab_pos[0], int(pos[1]) - host_ab_pos[1])
			else:
				pilot.host.tags.set('guard', 'x' + str(host_ab_pos[0]) + 'y' + str(host_ab_pos[1]))
				tile = pilot.host.pos
			target = tile
		return .on_turn()
