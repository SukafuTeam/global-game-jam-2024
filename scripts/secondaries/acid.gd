extends Node2D
class_name Acid

@onready var hurtbox: Area2D = $Hurtbox

@export var damage:int = 5

func _process(delta):
	var areas = hurtbox.get_overlapping_areas()
	for area in areas:
		if area.owner is Enemy:
			var en = area.owner as Enemy
			en.take_damage(damage, global_position)
