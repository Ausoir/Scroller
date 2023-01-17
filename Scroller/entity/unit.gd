extends "res://entity/item.gd"

const Pilot = preload("res://entity/pilot.gd")
const Action = preload("res://entity/action.gd")

onready var animation = $Animation
onready var sprite = $Sprite
onready var body = $Body

var delay = 0

var team = 2
var col_mask = 12
var pilot
var action = Action.new(self)
var skills = ["lunge", "knockdown", "flurry", "kick", "punch"]

func _ready():
	col = 14
	sprite.show()
	action.refresh_skills()

func get_type():
	return 2

func _physics_process(delta):
	._physics_process(delta)
	sprite.position = body.get_point_position(1)

func on_attack(_type, _dmg):
	pass

func possess(_ctlr = null):
	if _ctlr == null:
		_ctlr = Pilot.new()
		_ctlr.host = self
		_ctlr.set_ai([])
	else:
		_ctlr.unassign()
		_ctlr.host = self
	if pilot != null:
		pilot.remove()
		pilot = null
	pilot = _ctlr
	_ctlr.on_assign()

func on_kill(_victim):
	pass

func on_turn():
	.on_turn()
	if pos.state != null and pos.state[1] >= G.world.turn.turns:
		hit(pos.state[0], pos.state[2])
	else:
		pilot.on_turn()
		action.on_turn()

func hit(state, dir):
	face(dir)
	if state == "hit":
		action.hit()
	elif state == "bash":
		action.knockout()
	.hit(state, dir)

func on_land():
	action.delay = 0
	action.next_action = ["fall"]

func set_texture_from_path(path):
	if path != null:
		G.data.set_sprite_texture(sprite, path, 0)
		if sprite.texture != null:
			var img_size = sprite.texture.get_size()
			if img_size.y > G.H:
				sprite.offset.y = -int((img_size.y - G.H) / 2)

func die():
	pilot.on_die()
	.die()

func remove():
	if pilot != null:
		pilot.remove()
	for child in get_children():
		child.queue_free()
	.remove()

func relocate(p, force=false):
	.relocate(p, force)
	if pos.visible:
		update_z()

func set_animation(p, speed=1):
	if speed != 1:
		animation.play(p, -1, speed)
	else:
		animation.play(p)
	animation.seek(0)

func callback_animation(p):
	action.callv(p, [])
