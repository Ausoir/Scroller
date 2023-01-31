extends Control

onready var tween = $Tween

func display():
	show()
	var lvl = int(G.vars.xp / 100)
	var xp = str(int(int(G.vars.xp) % 100 / float(lvl*lvl+1) * 100))
	$Label.set_text("Level " + str(lvl) + " / " + xp + "%")
	for i in get_children():
		if i is RichTextLabel:
			i.queue_free()
	var skills = G.you.host.dat.get("skills", [])
	for i in range(max(lvl, skills.size())):
		var new
		if i >= skills.size():
			new = make_label("[center]---[/center]")
		else:
			var skillname = skills[i]
			var data = G.data.skill_data.get(skillname)
			if data != null:
				var color = data.get("color", "#333")
				var text = "[center][color="+color+"] " + skillname + " [/color][/center]"
				new = make_label(text)
				var color2 = data.get("color2", "#AAA")
				var stylebox = StyleBoxFlat.new()
				stylebox.bg_color = Color(color2)
				new.add_stylebox_override("normal", stylebox)
				new.connect("gui_input", self, "_on_input", [new, skillname])
				new.connect("mouse_entered", self, "_mouse_entered", [new, skillname])
				new.connect("mouse_exited", self, "_mouse_exited", [new, text])
		tween.interpolate_property(new, "rect_scale",
			Vector2(0, 1), Vector2.ONE, .1 + .1 * i,
			Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()

func make_label(text):
	var new = RichTextLabel.new()
	new.set_custom_minimum_size(Vector2(200, 36))
	new.set_use_bbcode(true)
	new.set_scroll_active(false)
	new.set_bbcode(text)
	add_child(new)
	return new

func _on_input(event, node, meta):
	if event is InputEventMouseButton:
		if event.is_pressed():
			_mouse_entered(node, meta)
		else:
			_mouse_exited(node, meta)
			G.you.host.drop_skill(meta)
			remove_child(node)
			display()

func _mouse_entered(node, meta):
	var text = "[center] [shake]" + meta + "[/shake] [/center]"
	node.set_bbcode(text)

func _mouse_exited(node, text):
	node.set_bbcode(text)
