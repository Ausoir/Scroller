extends "res://entity/item.gd"

const Pilot = preload("res://entity/pilot.gd")
const Action = preload("res://entity/action.gd")

onready var animation = $Animation
onready var body = $Body

var delay = 0

var team = 2
var col_mask = 8
var pilot
var injury = false
var action = Action.new(self)

func _ready():
	col = 2
	sprite.show()
	offset.y = 32
	G.world.turn.add(self)

func get_type():
	return 2

func set_color(p):
	body.set_default_color(p)
	for i in body.get_children():
		i.set_default_color(p)

func _physics_process(delta):
	._physics_process(delta)
	sprite.position = body.get_point_position(1)
	sprite.rotation = (sprite.position-body.get_point_position(0)).angle() + 1.57

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
	elif fall_height > 0:
		set_animation("fall")
	else:
		pilot.on_turn()
		action.on_turn()

func hit(state, dir):
	if col & 2 > 0:
		face(dir)
		action.set_action(["hit", state])
		.hit(state, dir)

func on_land():
	action.set_action(["land"])

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
	if check_overlap(p):
		if G.rng.b():
			offset.x += G.rng.ir(3, 7)
		else:
			offset.x += G.rng.ir(-7, -3)
	else:
		offset.x = 0
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

func _on_animation_finished(anim_name):
	action.on_animation_done(anim_name)

func check_overlap(targetpos):
	for item in targetpos.items:
		if is_instance_valid(item):
			if item.get_type() == 2:
				return true
	return false
