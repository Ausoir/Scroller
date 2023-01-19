extends "res://entity/item.gd"

onready var animation = $AnimationPlayer

func _ready():
	G.world.turn.add(self)
	set_color(Color(dat.get("color", "#000")))
	set_width(dat.get("width", 16))

func on_turn():
	if pos.state != null and pos.state[1] >= G.world.turn.turns:
		hit(pos.state[0], pos.state[2])

func hit(state, dir):
	if col & 2 > 0 and state == "heavy":
		face(dir)
		animation.play("die")
		set_col(0)

func set_color(p):
	sprite.set_default_color(p)

func set_width(p):
	sprite.set_width(p)
