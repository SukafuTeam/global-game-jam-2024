extends SecondaryItem
class_name Invincibility

@export var invicibility_time: float = 10.0
@export var cooldown_time:float = 20
var current_cooldown: float

# Called when the node enters the scene tree for the first time.
func _ready():
	current_cooldown = cooldown_time


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_cooldown += delta

func can_use() -> bool:
	return current_cooldown >= cooldown_time and Global.mana >= 1

func use(position: Vector2):
	Global.mana -=1
	var p = Global.player as PlayerController
	p.current_damage_cooldown = invicibility_time
	current_cooldown = - invicibility_time
