extends Node2D
class_name Chest

@onready var animation: AnimationPlayer = $AnimationPlayer

@export var options: PackedScene
@export var open_effect: AudioStream

var opened: bool


func _process(delta):
	pass

func open():
	if opened:
		return
	
	animation.play("open")
	SoundController.play_sfx(open_effect)
	opened = true
	
	var sce = options.instantiate()
	add_child(sce)
