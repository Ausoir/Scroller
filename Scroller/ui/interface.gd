extends CanvasLayer

onready var menu
onready var n_fps = $FPS
var last_touch_time = 0
var screen_size
var mouse_pos = Vector2()
var on = false

func _ready():
	G.get_tree().get_root().connect("size_changed", self, "on_resize")
	on_resize()
	fadein()

func on_resize():
	screen_size = get_viewport().get_size_override()
	$Animation/Fade.set_size(screen_size)

func fadein():
	$Animation.play("FadeIn")

func _process(_delta):
	last_touch_time += _delta
	if G.vars.setting.showfps:
		n_fps.set_text(str(Engine.get_frames_per_second())+' FPS')

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()
	elif event is InputEventMouseButton:
		if event.is_pressed():
			last_touch_time = 0
	elif event is InputEventKey:
		if menu != null:
			menu.input_key()

func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("ui_exit"):
			G.game.end_game()
		elif Input.is_action_just_pressed("ui_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		elif G.you.host != null:
			G.you._on_input(event)
	elif !on:
		G.you._on_input(event)

func display(_arg):
	if !on:
		on = true
		G.you.unhandled_input = false

func clear():
	on = false
