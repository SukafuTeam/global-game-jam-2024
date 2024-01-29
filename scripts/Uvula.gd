extends Sprite2D

@export var speed: float = 2
@export var strength: float = 10

var time: float = 0

func _process(delta):
	time += delta
	
	var percent = sin(time * speed) * strength
	rotation_degrees = percent
