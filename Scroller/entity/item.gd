extends "res://entity/object.gd"

onready var sprite = $Sprite
var offset = Vector2()
var position_speed = 4
var dir = 1
var tags = []
var light = 0
var pos
var flash_state = [0, 0, 0, 0]
var beneath
var fall_height = 0

func _ready():
	hide()
	set_process(false)

func get_type():
	return 1

func get_default_team():
	return 0

func set_col(p):
	if pos.visible:
		if p & 1 == 0 and pos.is_col(1):
			G.you.view_dirty = 1
		elif p & 1 > 0 and !pos.is_col(1):
			G.you.view_dirty = max(1, pos.light - G.time.ambient_light)
	col = p
	pos.update_tile()

func face(_dir):
	dir = _dir
	if (dir > 0) != (scale.x > 0):
		scale.x *= -1

func face_toward(p):
	if p != null:
		var diffx = (p - pos.x)
		if diffx > 0:
			face(1)
		elif diffx < 0:
			face(-1)

func remove():
	set_process(false)
	set_physics_process(false)
	if light > 0:
		G.you.view_dirty = light
		G.world.turn.light_sources.erase(self)
	pos.remove_item(self)
	G.world.turn.remove(self)
	if pos.visible:
		if col & 1 == 0 and pos.is_col(1):
			G.you.view_dirty = 1
		elif col & 1 > 0 and !pos.is_col(1):
			G.you.view_dirty = max(1, pos.light - G.time.ambient_light)
	queue_free()

func die():
	remove()

func on_turn():
	if !beneath.is_col(12):
		fall_height += 1
		position_speed = -1
		relocate(beneath)
		if pos.y == G.world.size.y-1:
			die()
	elif fall_height > 0:
		on_land()

func on_land():
	fall_height = 0

func hit(_force, _dir):
	pos.state = null

func relocate(to, force=false):
	if force:
		if pos == null:
			pos = to
		position.x = to.position.x
		position.y = to.position.y
		set_process(true)
	elif pos != to:
		set_process(true)
	else:
		return
	pos.remove_item(self)
	to.add_item(self)
	beneath = to.get_neighbor(0, 1)
	if to.visible:
		if col & 1 == 0 and to.is_col(1):
			G.you.view_dirty = 1
		elif col & 1 > 0 and !to.is_col(1):
			G.you.view_dirty = 1

func _physics_process(_delta):
	if position_speed > 0:
		var diff = pos.position + offset - position
		position += diff * position_speed * 0.002
		position_speed = min(16, position_speed+1)
	else:
		var diff = pos.position + offset - position
		position += diff * -position_speed * 0.01
		position_speed = max(-16, position_speed-0.5)

func _process(delta):
	if flash_state[0] > 0:
		var percent = flash_state[0] / flash_state[1]
		if flash_state[2] > 0:
			modulate.r = 1
			modulate.g = 1-flash_state[2]*percent
			modulate.b = modulate.g
		elif flash_state[3] > 0:
			modulate.r = 1-flash_state[3]*percent
			modulate.g = 1
			modulate.b = modulate.r
		flash_state[0] -= delta
		if flash_state[0] <= 0:
			modulate = Color.white
	else:
		set_process(false)

func flash(c, dur):
	dur = max(.1, dur)
	flash_state = [dur, dur, 0, 0]
	flash_state[2 + c] = 1
	set_process(true)

func set_texture_from_path(path):
	if path != null:
		G.data.set_sprite_texture(sprite, path, 0)
		var img_size = sprite.texture.get_size()
		if img_size.y > G.H:
			sprite.offset.y = -int((img_size.y - G.H) / 2)

func cast_light(mag, row, start, end, flips):
	if start < end:
		return
	var new_start
	for cell in range(row, mag + 1):
		var dx = -cell - 1
		var dy = -cell
		var blocked = false
		while dx <= 0:
			dx += 1
			var start_slope = (dx - 0.5) / (dy + 0.5)
			var end_slope = (dx + 0.5) / (dy - 0.5)
			if start < end_slope:
				continue
			elif end > start_slope:
				break
			else:
				var tile_x = dx * flips[0] + dy * flips[1]
				var tile_y = dx * flips[2] + dy * flips[3]
				var map_x = pos.get_x() + tile_x
				var map_y = pos.get_y() + tile_y
				if G.world.is_inbound(map_x, map_y):
					var tile = G.world.get_tile(map_x, map_y)
					if tile:
						tile.set_light(mag - max(abs(tile_x), abs(tile_y)))
						if blocked:
							if tile.is_col(1):
								new_start = end_slope
							else:
								blocked = false
								start = new_start
						else:
							if tile.is_col(1) and cell < mag:
								blocked = true
								cast_light(mag, cell + 1, start, start_slope, flips)
								new_start = end_slope
		if blocked:
			break
