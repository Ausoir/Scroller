extends Node

var current = -1
var nodes
var size
var open

func _ready():
	nodes = []
	open = []
	size = get_child_count()
	for i in range(size):
		open.append(i)
		var node = get_node(str(i))
		nodes.append(node)
		node.connect("finished", self, "on_finished", [i])

func adjust_sound():
	var db = G.vars.setting.volume - 50
	for player in nodes:
		player.set_volume_db(db)

func play(sound, ppos):
	if G.camera.is_pos_in_range(ppos):
		var index = find_player()
		if index != -1:
			var player = nodes[index]
			player.position = ppos.position
			player.set_stream(G.data.get_sound(sound))
			player.play(0)

func find_player():
	if open.empty():
		return -1
#		current += 1
#		if current >= size:
#			current = 0
#		return current
	return open.pop_front()

func on_finished(p):
	open.append(p)
