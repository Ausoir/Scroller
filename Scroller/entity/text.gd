extends "res://entity/item.gd"

onready var animation = $AnimationPlayer

func set_skill(text):
	dat["skill"] = text
	var data = G.data.skill_data.get(text)
	var color1 = data.get("color", "#333")
	var color2 = data.get("color2", "#AAA")
	$Viewport/Label.set_text(text)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color2
	$Viewport/Label.add_stylebox_override("normal", stylebox)
	$Viewport/Label.add_color_override("font_color", Color(color1))
	sprite.set_texture($Viewport.get_texture())
	animation.play("drop")
