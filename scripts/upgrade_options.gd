extends Node2D

@onready var start_point: Marker2D = $OriginPoint
@onready var weapon_pos: Marker2D = $WeaponChoicePos
@onready var secondary_pos: Marker2D = $SecondaryChoicePos

@onready var weapon_area: Area2D = $WeaponChoice
@onready var secondary_area: Area2D = $SecondaryChoice

@onready var weapon_sprite: Sprite2D = $WeaponChoice/WeaponChoise
@onready var secondary_sprite: Sprite2D = $SecondaryChoice/SecondaryChoise

var weapon_index: int
var secondary_index: int

var can_pick: bool

var time: float = 0

func _ready():
	can_pick = false
	weapon_index = Global.get_random_weapon()
	secondary_index = Global.get_random_secondary()
	
	weapon_sprite.texture = Global.weapons[weapon_index].icon
	secondary_sprite.texture = Global.secondaries[secondary_index].icon
	
	weapon_area.scale = Vector2.ZERO
	secondary_area.scale = Vector2.ZERO
	
	weapon_area.global_position = start_point.global_position
	secondary_area.global_position = start_point.global_position
	
	weapon_area.body_entered.connect(picked_weapon)
	secondary_area.body_entered.connect(picked_secondary)
	
	var tween = create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(
		weapon_area, 
		"global_position",
		start_point.global_position + Vector2(0, -300),
		0.5
	)
	tween.parallel().tween_property(
		secondary_area, 
		"global_position",
		start_point.global_position + Vector2(0, -300),
		0.5
	)
	tween.parallel().tween_property(
		weapon_area,
		"scale",
		Vector2.ONE,
		0.5
	)
	tween.parallel().tween_property(
		secondary_area,
		"scale",
		Vector2.ONE,
		0.5
	)
	tween.tween_interval(0.5)
	tween.tween_property(
		weapon_area,
		"global_position",
		weapon_pos.global_position,
		0.5
	)
	tween.parallel().tween_property(
		secondary_area,
		"global_position",
		secondary_pos.global_position,
		0.5
	)
	tween.tween_callback(func():
		can_pick = true
		time = 0
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !can_pick:
		return
	
	time += delta
	
	weapon_sprite.position.y = sin(time * 5) * 10
	secondary_sprite.position.y = sin(time * 5) * 10
	
func picked_weapon(body):
	if !(body is PlayerController) or !can_pick:
		return
	Global.equip_weapon(weapon_index)
	queue_free()

func picked_secondary(body):
	if !(body is PlayerController) or !can_pick:
		return
	
	Global.equip_secondary(secondary_index)
	queue_free()
	
