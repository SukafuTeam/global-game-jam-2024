extends Node2D
class_name Lure

signal finished

@onready var body_container: Marker2D = $BodyContainer
@onready var hitbox: Area2D = $Area2D

@export var lifetime: float = 20.0
@export var damage_cooldown_time: float = 0.1
var current_damage_cooldown: float

var original_player: Node2D

func _ready():
	original_player = Global.player
	Global.player = self
	
	body_container.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(
		body_container,
		"scale",
		Vector2.ONE,
		0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
func _process(delta):
	lifetime -= delta
	
	if lifetime <= 0.0:
		finish()
	
	current_damage_cooldown -= delta
	if current_damage_cooldown > 0:
		return
	
	var areas = hitbox.get_overlapping_areas()
	for area in areas:
		if!(area.owner is Enemy):
			continue
		
		current_damage_cooldown = damage_cooldown_time
		body_container.rotation_degrees = randf_range(-30, 30)

func finish():
	Global.player = original_player
	finished.emit()
	queue_free()
