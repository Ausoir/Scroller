extends "res://entity/item.gd"

onready var animation = $AnimationPlayer

func set_xp(p):
	$Sprite.mesh.size.x = 160
	dat["xp"] = p
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = "#00000000"
	$Viewport/Label.set_text("LEVEL < " + str(p))
	$Viewport/Label.add_color_override("font_color", Color.blueviolet)
	$Viewport/Label.add_stylebox_override("normal", stylebox)
	sprite.set_texture($Viewport.get_texture())
	animation.play("drop")

func set_skill(text):
	dat["skill"] = text
	var data = G.data.skill_data.get(text)
	if data != null:
		var color1 = data.get("color", "#333")
		var color2 = data.get("color2", "#AAA")
		$Viewport/Label.set_text(text)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = color2
		$Viewport/Label.add_stylebox_override("normal", stylebox)
		$Viewport/Label.add_color_override("font_color", Color(color1))
		sprite.set_texture($Viewport.get_texture())
		animation.play("drop")
