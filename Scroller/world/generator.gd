var vaults = preload("res://world/vaults.gd").new()
var width
var height
var terrains
var objects
var entrance
var exits

func generate(biome):
	width = 62
	height = 42
	G.rng.set_seed(G.vars.seed + 3456789)
	var v = place_vault(Vector2(), biome, [0], G.rng.f())
	terrains = v[1]
	objects = v[2]
	width = terrains[0].size()
	height = terrains.size()
	exits = []
	for y in range(height):
		for x in range(width):
			if terrains[y][x] == "@":
				entrance = [x, y]
				terrains[y][x] = "O"
			elif terrains[y][x] == "*":
				exits.append([x, y])
				terrains[y][x] = "O"
	return v

func place_vault(pos, structure, dirs, sd, flip=0):
	if vaults.load_vault(structure):
		var dir = G.rng.r_arr(dirs)
		if dir != null:
			vaults.rot = dir
		vaults.flip = flip
		var bounds = [pos.x, pos.y]
		return vaults.make_vault(sd, bounds)

func assign_area(area_data, value):
	for area in area_data:
		if value < area[0]:
			return area
