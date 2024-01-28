extends Sprite2D

@export var speed: float = 2
@export var strength: float = 10

var time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	
	var percent = sin(time * speed) * strength
	rotation_degrees = percent
