extends Node2D
class_name Chest

@onready var animation: AnimationPlayer = $AnimationPlayer

var opened: bool


func _process(delta):
	pass

func open():
	if opened:
		return
	
	animation.play("open")
	opened = true
