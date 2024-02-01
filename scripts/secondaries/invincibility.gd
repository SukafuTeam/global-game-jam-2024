extends SecondaryItem
class_name Invincibility

@export var invicibility_time: float = 10.0
@export var cooldown_time:float = 20
var current_cooldown: float

@export var invibility_color: Color

func _ready():
	current_cooldown = cooldown_time

func _process(delta):
	current_cooldown += delta

func can_use() -> bool:
	return current_cooldown >= cooldown_time and Global.mana >= 1

func get_cooldown():
	return inverse_lerp(0, cooldown_time, current_cooldown)

func use(_player_position: Vector2):
	Global.mana -=1
	var p = Global.player as PlayerController
	p.current_damage_cooldown = invicibility_time
	current_cooldown = - invicibility_time
	p.animation_body.material.set_shader_parameter("color", invibility_color)
