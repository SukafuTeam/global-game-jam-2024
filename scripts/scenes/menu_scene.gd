extends CanvasLayer


var transitioning: bool

@export var menu_music: AudioStream
@onready var player: Node2D = $background/Vineboom/PlayerAnimation

# Called when the node enters the scene tree for the first time.
func _ready():
	SoundController.change_bmg("menu", menu_music)
	Global.reset_stats()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if transitioning:
		return
	
	if Input.is_action_just_pressed("attack"):
		
		var origin = player.global_position + Vector2(0, -50)
		var target = Vector2(960, 540)
		
		CircleTransition.transtition(origin, target, "res://scenes/arena_scene.tscn")
