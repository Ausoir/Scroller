extends Node

const Turn = preload("res://tool/turn.gd")
const Tile = preload("res://world/tile.gd")
var tileset
var generator
var turn = Turn.new()
var size
var sound
var tiles
var mapname

onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var shadowmap = $Shadowmap
onready var items = $Items
onready var overlay = $Overlay
onready var background = $Background
var team = [[], [], []]

func _ready():
	tileset = TileSet.new()
	tilemap.set_tileset(tileset)
	set_process(false)
	generator = load("res://world/generator.gd").new()
	var count = 0
	for key in G.data.terrain_data:
		var terrain = G.data.terrain_data[key]
		var aut = terrain.get("autotile", 1)
		for i in range(aut):
			tileset.create_tile(count)
			var path = terrain.img + " (" + str(i+1) + ")"
			tileset.tile_set_name(count, path)
			if aut == 1:
				tileset.tile_set_texture(count, G.data.get_image(terrain.img))
			else:
				tileset.tile_set_texture(count, G.data.get_image(path))
			count += 1
	G.world = self

	create(G.vars.map)
	add_child(G.sfx)
	overlay.add_child(G.you)
	G.you.unserialize()
	G.get_tree().set_pause(false)

func create(_name):
	remove()
	mapname = _name
	var metadata = generator.generate(_name)[0][0]
	if 'color' in metadata:
		background.texture.gradient.set_color(0, Color(metadata.color[0]))
		background.texture.gradient.set_color(1, Color(metadata.color[1]))
	unserialize(generator.terrains, generator.objects)
	for y in range(-15, size.y+1):
		for x in range(size.x, size.x+10):
			shadowmap.set_cell(x, y, 1)
		for x in range(-10, 0):
			shadowmap.set_cell(x, y, 1)
	for y in range(size.y+1):
		for x in range(size.x):
			shadowmap.set_cell(x, y, 0)
			if x >= 0 and y >= 0 and x < size.x and y < size.y:
				var tile = tiles[y][x]
				tile.set_visible(false)
				if tile.height > 0:
					shademap.set_cell(x, y, 0)
	tilemap.update_bitmask_region(Vector2(), size)
	shademap.update_bitmask_region(Vector2(), size)
	$Background.position = Vector2(size.x * G.HW, size.y * G.HH - G.ui.screen_size.y/2)
	$Background.scale = Vector2(size.y * G.W + G.ui.screen_size.y, size.x * G.H + G.ui.screen_size.x)

func spawn_mob():
	var mob = G.data.vars.habitat.get(mapname)
	for _i in range(8):
		var x = G.rng.ir(0, size.x-1)
		var y = G.rng.ir(0, size.y-2)
		for yy in range(y, size.y-1):
			var tile = tiles[yy][x]
			if !tile.is_col(8) and tiles[yy+1][x].is_col(8):
				G.factory.make_any(mob, tile)
				return

func set_dark(tile):
	if tile.visible:
		tile.set_visible(false)
		shadowmap.set_cell(tile.x, tile.y, 1)

func set_light(tile):
	if !tile.visible:
		tile.set_visible(true)
		shadowmap.set_cell(tile.x, tile.y, -1)

func create_map(sx, sy):
	tiles = []
	for y in range(sy):
		var row = []
		for x in range(sx):
			row.append(Tile.new(x, y))
		tiles.append(row)

func remove():
	if tiles != null:
		for row in tiles:
			for cell in row:
				for item in cell.items:
					if item != G.you.host:
						item.remove()
				cell.queue_free()
	tilemap.clear()
	shademap.clear()
	shadowmap.clear()

func get_tile(x, y):
	if is_inbound(x, y):
		return tiles[y][x]

func get_tile_clamped(x, y):
	return tiles[clamp(y, 0, size.y-1)][clamp(x, 0, size.x-1)]

func from_vec(v):
	var x = int(v.x / G.W)
	var y = int(v.y / G.H)
	return tiles[y][x]

func add_item(x, y, val):
	tiles[y][x].items.append(val)

func is_inbound(x, y):
	return x >= 0 and x < size.x and y >= 0 and y < size.y

func fit_bound(x, y):
	return tiles[clamp(y, 0, size.y-1)][clamp(x, 0, size.x-1)]

func get_spawn_point():
	var pt = G.rng.r_arr(generator.special_points)
	var r = G.world.get_tile(pt[0], pt[1])
	return r

func unserialize(line_terrains, line_objects):
	if line_terrains[0] is Array:
		size = Vector2(line_terrains[0].size(), line_terrains.size())
	else:
		size = Vector2(line_terrains[0].length(), line_terrains.size())
	create_map(size.x, size.y)
	for y in range(size.y):
		for x in range(size.x):
			var tile = tiles[y][x]
			var terrain = line_terrains[y][x]
			tile.set_terrain(terrain)
			var obj = line_objects[y][x]
			if obj != null:
				G.factory.make_any(obj, tile)
