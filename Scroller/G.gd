extends Node

const W = 64
const H = 64
const HW = 32
const HH = 32
const AUTOTILE_COORD = [Vector2(0,0),Vector2(0,3*H),Vector2(W,0),Vector2(W,3*H),Vector2(0,H),Vector2(0,2*H),Vector2(W,H),Vector2(W,2*H),Vector2(3*W,0),Vector2(3*W,3*H),Vector2(2*W,0),Vector2(2*W,3*H),Vector2(3*W,H),Vector2(3*W,2*H),Vector2(2*W,H),Vector2(2*W,2*H)]
const V = 1024
const C = 17
const CH = 3
const CARDINALS = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
const CARDINAL_ROTATIONS = [0, PI/2, PI, -PI/2]
const DIRS = [Vector2.UP,Vector2(1,-1),Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),Vector2.LEFT,Vector2(-1,-1)]
const UP = 0
const UPRIGHT = 1
const RIGHT = 2
const DOWNRIGHT = 3
const DOWN = 4
const DOWNLEFT = 5
const LEFT = 6
const UPLEFT = 7

const Damage_Label = preload("res://fx/particles/Damage_Label.tscn")
const Gfx = preload("res://fx/Gfx.tscn")
var rng = preload("res://tool/rng.gd").new()
var game = preload("res://tool/gamestate.gd").new()
var L = preload("res://tool/lang.gd").new()
var ui = preload("res://ui/Interface.tscn").instance()
var sfx
var fx = preload("res://tool/fx.gd").new()
var data = preload("res://tool/json.gd").new()
var time
var factory = preload("res://tool/factory.gd").new()
var world
var census
var event = preload("res://tool/event.gd").new()
var events
var vars
var settings = {"sound":50, "showfps":false}
var you
var camera
var generator

func _ready():
	vars = {}
	time = preload("res://tool/time.gd").new()
	sfx = preload("res://fx/Sfx.tscn").instance()
	you = preload("res://entity/Player.tscn").instance()
	camera = preload("res://world/Camera.tscn").instance()
	generator = preload("res://world/generator.gd").new()
	events = []
	add_child(ui)
	add_child(camera)
	time.reset()
	add_child(time)
	camera.set_process(false)
	time.set_process(false)

func vec_to_tile(vec):
	var x = floor(vec.x / W)
	var y = floor(vec.y / H)
	if G.world.is_inbound(x, y):
		return G.world.get_tile(x, y)

func vec_to_pos(vec):
	return Vector2(vec.x/W, vec.y/H).floor()

func pos_to_vec(x, y):
	return Vector2(x*W+HW, y*H+HH)

func get_face(x1, x2):
	if x1 < x2:
		return 1
	else:
		return -1

func vector_to_dir(x, y):
	var count = 0
	for i in DIRS:
		if i[0] == x and i[1] == y:
			return count
		count += 1
	return -1

func make_particle(arg, pos, args=null, force=false):
	if (force and camera.is_pos_in_range(pos)) or pos.visible:
		var r = data.get_particle(arg)
		r.position = pos.position
		r.add()
		if args != null:
			r.run_details(args)
		return r

func display_damage(val, pos, color=Color.white, _scale=1, _speed=800):
	if pos.visible:
		var r = Damage_Label.instance()
		r.position = pos.position
		r.position.y -= H
		world.overlay.add_child(r)
		r.set_damage(str(val), color, _scale, _speed)

func run(p, param):
	return event.run(p, param)

func add_event(countdown, newevent, params=[]):
	events.append([countdown, newevent, params])
