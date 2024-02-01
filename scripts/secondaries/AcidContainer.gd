extends SecondaryItem
class_name AcidContainer

@export var acid: PackedScene

@export var burn_time: float = 10.0
@export var cooldown_time: float = 20.0
var current_cooldown_time

func _ready():
	current_cooldown_time = cooldown_time

func _process(delta):
	current_cooldown_time += delta
	
func can_use() -> bool:
	return current_cooldown_time >= cooldown_time and Global.mana >= 1

func get_cooldown():
	return inverse_lerp(0, cooldown_time, current_cooldown_time)

func use(_player_position: Vector2):
	Global.mana -=1
	current_cooldown_time = -burn_time
	
	var ins = acid.instantiate()
	add_child(ins)
	ins.global_position = global_position
	
	await get_tree().create_timer(burn_time).timeout
	
	ins.queue_free()
