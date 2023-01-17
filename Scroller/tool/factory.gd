const Item = preload("res://entity/Item.tscn")
const Unit = preload("res://entity/Unit.tscn")

func make_any(name, pos=null):
	if name[0] == "#":
		return make_group(name, pos)
	var r = make_item(name, pos)
	if r == null:
		r = make_unit(name, pos)
	return r

func make_unit(name, pos):
	var json = G.data.unit_data.get(name)
	if json != null:
		var r = Unit.instance()
		r.dat = json.duplicate()
		if pos != null:
			r.relocate(pos, true)
		r.team = r.dat.get("team", 2)
		G.world.team[r.team].append(r)
		if r.team != 1:
			r.possess()
		return r

func make_item(name, pos):
	var json = G.data.item_data.get(name)
	if json != null:
		var r = Item.instance()
		r.dat = json.duplicate()
		if pos != null:
			r.relocate(pos, true)
		return r

func make_group(arg, pos):
	var groups = G.data.get_group(arg)
	if !groups.empty():
		var made
		var adjs
		var adj = pos
		for group in groups:
			for _i in range(group[1]):
				if adj != null:
					made = make_any(group[0], adj)
					if made != null and made.col & 4 > 0:
						adjs = adj.get_available_adjacents(12)
						adj = G.rng.r_arr(adjs)
		return made
