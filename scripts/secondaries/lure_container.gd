extends SecondaryItem
class_name LureContainer

@export var lure_scene: PackedScene

@export var cooldown: float = 5.0
var current_cooldown_time: float
var active: bool

func _ready():
	current_cooldown_time = cooldown

func _process(delta):
	current_cooldown_time += delta
	
func can_use() -> bool:
	if active:
		return false
	
	return current_cooldown_time >= cooldown and Global.mana >= 1
	
func get_cooldown():
	return inverse_lerp(0, cooldown, current_cooldown_time)

func use(player_position: Vector2):
	Global.mana -= 1
	current_cooldown_time = -1000000
	active = true
	var ins = lure_scene.instantiate() as Lure
	add_child(ins)
	ins.global_position = player_position
	ins.finished.connect(func():
		current_cooldown_time = 0
		active = false
	)
