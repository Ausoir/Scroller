extends "res://entity/item.gd"

const Pilot = preload("res://entity/pilot.gd")
const Action = preload("res://entity/action.gd")

onready var animation = $Animation
onready var body = $Body
onready var chat = $Chat

var delay = 0

var col_mask = 8
var pilot
var injury = false
var gene = -1
var action = Action.new(self)
var ded = false

func _ready():
	sprite.show()
	offset.y = 32
	chat.host = self
	G.world.turn.add(self)

func get_type():
	return 2

func set_seed(p):
	gene = p
	if gene == -1:
		gene = G.rng.ir(0, 999999)
	var size = 1.1 + gene % 16 * .01
	set_scale(Vector2(size, size))

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
		_ctlr.set_ai(dat.get("ai", []))
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

func face(_dir):
	.face(_dir)
	if scale.x < 0:
		chat.scale.x = -.5
	else:
		chat.scale.x = .5

func on_turn():
	.on_turn()
	chat._on_turn()
	if pos.state != null and pos.state[1] >= G.world.turn.turns and pos.state[3] != team:
		hit(pos.state[0], pos.state[2])
	elif fall_height > 0:
		pilot.on_turn()
		set_animation("fall")
	else:
		pilot.on_turn()
		action.on_turn()

func hit(state, from):
	if col & 2 > 0:
		face_toward(from)
		action.set_action(["hit", state])
		.hit(state, from)

func on_land():
	action.set_action(["land", fall_height])
	.on_land()

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
	if !p.get_items_by_type(2).empty():
		if G.rng.b():
			offset.x += G.rng.ir(3, 7)
		else:
			offset.x += G.rng.ir(-7, -3)
	else:
		offset.x = 0
	.relocate(p, force)

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

func drop_item(item):
	var r = G.factory.make_item("item", pos)
	if typeof(item) <= 3:
		r.set_xp(item)
	else:
		dat.get("skills", []).erase(item)
		r.set_skill(item)
	return r

func drop_loot():
	var loot = dat.get("loot")
	if loot != null:
		if loot is Array:
			drop_item(G.rng.r_arr(loot))
		else:
			drop_item(loot)
	else:
		var skills = dat.get("skills", [])
		if G.rng.r_percent(0.2):
			drop_item(G.rng.r_arr(skills))
		elif G.rng.r_percent(0.01):
			var rskill = G.rng.r_arr(G.data.skill_data.keys())
			drop_item(rskill)
