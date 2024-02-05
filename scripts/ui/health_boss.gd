extends CanvasLayer
class_name HealthBoss

@onready var raiz: TextureRect = $Container/RaziMeio
@onready var back_bar: TextureProgressBar = $Container/RaziMeio/Background/BackBar
@onready var front_bar: TextureProgressBar = $Container/RaziMeio/Background/Frontbar

@export var back_bar_time: float = 0.05
var current_back_bar_time: float

var max_health

func _ready():
	current_back_bar_time = back_bar_time
	var final_position: Vector2 = Vector2(436, 929)
	raiz.position = Vector2(436, 1500)
	
	var tween = create_tween()
	tween.tween_property(raiz, "position", final_position, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func setup(initial_value: int):
	max_health = initial_value
	
	back_bar.max_value = 1000
	back_bar.value = 1000
	
	front_bar.max_value = 1000
	front_bar.value = 1000

func update_health(new_health: int):
	front_bar.value = inverse_lerp(0, max_health, new_health) * 1000

func _process(delta):
	if front_bar.value < back_bar.value:
		back_bar.value -= 1
