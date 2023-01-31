extends Node2D

var lifetime = 0
var host

func _ready():
	$Mesh.set_texture($Mesh/Viewport.get_texture())

func say(p):
	if p != null:
		$Mesh/Viewport/Label.set_text(p)
		show()
		lifetime = 12 + int(p.length() / 4)

func say_personalized(p):
	if !p.empty():
		var personality = host.gene % p.size()
		if p[personality] != null:
			say(p[personality])

func _on_turn():
	if lifetime == 0:
		$Mesh/Viewport/Label.set_text("")
		hide()
	elif lifetime > 0:
		lifetime -= 1
