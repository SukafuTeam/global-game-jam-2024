extends CanvasLayer


var transitioning: bool

@export var menu_music: AudioStream

# Called when the node enters the scene tree for the first time.
func _ready():
	SoundController.change_bmg("menu", menu_music)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if transitioning:
		return
	
	if Input.is_action_just_pressed("attack"):
		var origin = Vector2(170, 600)
		var target = Vector2(960, 540)
		
		CircleTransition.transtition(origin, target, "res://scenes/arena_scene.tscn")
