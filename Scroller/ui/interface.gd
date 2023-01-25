extends CanvasLayer

const ICON_PLAYER = preload("res://assets/images/icon_player.png")
const ICON_SETTINGS = preload("res://assets/images/icon_settings.png")
onready var menu_skills = $Menu/Skills
onready var menu_settings = $Menu/Settings
onready var menu_button = $MenuButton
onready var n_fps = $FPS
var last_touch_time = 0
var screen_size
var mouse_pos = Vector2()
var on = false

func _ready():
	G.get_tree().get_root().connect("size_changed", self, "on_resize")
	on_resize()
	fadein()
	menu_skills.hide()

func on_resize():
	screen_size = get_viewport().get_size_override()
	$Animation/Fade.set_size(screen_size)

func fadein():
	$Animation.play("fadein")

func _process(_delta):
	last_touch_time += _delta
	if G.vars.setting.showfps:
		n_fps.set_text(str(Engine.get_frames_per_second())+' FPS')

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()
	elif event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoom in"):
			G.you.zoom(.9)
		elif Input.is_action_just_pressed("zoom out"):
			G.you.zoom(1.1)
		elif event.is_pressed():
			last_touch_time = 0
	elif event is InputEventKey:
		if Input.is_action_just_pressed("ui_exit"):
			if !on:
				display(1)
			else:
				clear()
		elif Input.is_action_just_pressed("ui_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		elif Input.is_action_just_pressed("ui_menu"):
			if !on:
				display(0)
			else:
				clear()
		elif Input.is_action_just_pressed("use"):
			clear()
		return
	if !on:
		G.you._on_input(event)

func display(p):
	if !on:
		on = true
		$Animation.play("tint")
		menu_button.show()
		if p == 0:
			menu_skills.display()
			menu_button.set_normal_texture(ICON_SETTINGS)
		elif p == 1:
			menu_settings.display()
			menu_button.set_normal_texture(ICON_PLAYER)

func clear():
	on = false
	$Animation.stop()
	$Animation/Fade.color = Color.transparent
	menu_button.hide()
	menu_skills.hide()
	menu_settings.hide()

func _on_button_pressed():
	if menu_settings.visible:
		clear()
		display(0)
	elif menu_skills.visible:
		clear()
		display(1)
