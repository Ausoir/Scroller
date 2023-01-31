const Unit = preload("res://entity/Unit.tscn")
const Item = preload("res://entity/Item.tscn")
const Door = preload("res://entity/Door.tscn")
const Text = preload("res://entity/Text.tscn")

func make_any(name, pos=null):
	if name[0] == "#":
		return make_group(name, pos)
	var r = make_item(name, pos)
	if r == null:
		r = make_unit(name, pos)
	return r

func make_unit(name, pos, data=null):
	var json = G.data.unit_data.get(name)
	if json != null:
		var r = Unit.instance()
		assign_dat(r, combine_data(json, data), pos)
		r.set_col(int(r.dat.get("col", 2)))
		r.team = r.dat.get("team", -1)
		r.set_seed(r.dat.get("seed", -1))
		G.world.team[r.team].append(r)
		for i in r.dat.get("skills", []):
			r.action.skills.append(i)
		r.set_color(Color(r.dat.get("color", "#000")))
		if !("ai" in r.dat) or r.dat.ai != null:
			r.possess()
		return r

func make_item(name, pos):
	var r
	var json = G.data.item_data.get(name)
	if json != null:
		if json.get("class") == "door":
			r = Door.instance()
		elif json.get("class") == "text":
			r = Text.instance()
		else:
			r = Item.instance()
		assign_dat(r, json, pos)
		r.set_col(int(r.dat.get("col", 0)))
	return r

func combine_data(orig, add):
	var v = {}
	for key in orig:
		if add != null and key in add:
			v[key] = add[key]
		else:
			var value = orig[key]
			if value is Dictionary or value is Array:
				v[key] = value.duplicate()
			else:
				v[key] = value
	return v

func assign_dat(item, json, pos):
	item.dat = json
	if pos != null:
		item.relocate(pos, true)
	item.set_texture_from_path(item.dat.get("img"))
	item.z_index = item.dat.get("z", 0)

func make_group(arg, pos):
	var groups = G.data.get_group(arg)
	if !groups.empty():
		var made
		for group in groups:
			for _i in range(group[1]):
				made = make_any(group[0], pos)
		return made
