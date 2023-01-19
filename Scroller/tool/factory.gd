const Item = preload("res://entity/Item.tscn")
const Door = preload("res://entity/Door.tscn")
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
		assign_dat(r, json, pos)
		r.team = r.dat.get("team", 2)
		G.world.team[r.team].append(r)
		for i in r.dat.get("skills", []):
			r.action.skills.append(i)
		r.set_color(Color(r.dat.get("color", "#000")))
		if r.team != 1:
			r.possess()
		return r

func make_item(name, pos):
	var r
	var json = G.data.item_data.get(name)
	if json != null:
		if json.get("class") == "door":
			r = Door.instance()
		else:
			r = Item.instance()
		assign_dat(r, json, pos)
	return r

func assign_dat(item, json, pos):
	item.dat = json.duplicate()
	if pos != null:
		item.relocate(pos, true)
	item.set_col(int(item.dat.get("col", 0)))
	item.set_texture_from_path(item.dat.get("img"))

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
