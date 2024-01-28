extends SecondaryItem
class_name ShieldItem

signal finished

@onready var shield: Node2D = $BodyContainer

@export var cooldown_time: float = 5.0
var current_cooldown_time: float
var active: bool


func _ready():
	current_cooldown_time = cooldown_time
	shield.hide()

func _process(delta):
	if active:
		return
	
	current_cooldown_time += delta

func can_use() -> bool:
	if active:
		return false
	return current_cooldown_time > cooldown_time and Global.mana >= 1

func use(position: Vector2):
	Global.mana -= 1
	
	active = true
	shield.show()
	shield.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.tween_property(shield, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	current_cooldown_time = -1000000

func used():
	active = false
	current_cooldown_time = 0
	shield.hide()
