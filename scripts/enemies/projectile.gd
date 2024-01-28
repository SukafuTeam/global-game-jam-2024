class_name Projectile
extends Area2D

@onready var visible_notif: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

@export var rotation_speed: float = 500
@export var move_speed: float = 600.0
var move_direction: Vector2 = Vector2.RIGHT

func _ready():
	visible_notif.screen_exited.connect(func(): queue_free())

# Called when the node enters the scene tree for the first time.
func setup(direction):
	move_direction = direction

func _process(delta):
	if move_direction.x > 0:
		rotation_degrees += rotation_speed * delta
	else:
		rotation_degrees -= rotation_speed * delta
	position += move_direction * delta * move_speed
