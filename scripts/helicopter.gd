extends Node2D

@onready var box: Sprite2D = $Box
@onready var strand: Sprite2D = $Strand

@onready var player_animation: Node2D = $Strand/PlayerPos/PlayerAnimation
@onready var animation: AnimationPlayer = $Strand/PlayerPos/PlayerAnimation/Animations
@onready var hand1: Sprite2D = $Strand/Hand1
@onready var hand2: Sprite2D = $Strand/Hand2

@onready var pos: Marker2D = $Strand/PlayerPos

@onready var trigger: Area2D = $Trigger
var finished_animation: bool

func _ready():
	animation.play("attack_down")
	player_animation.hide()
	hand1.hide()
	hand2.hide()
	
	trigger.area_entered.connect(on_area_entered)
	
	strand.position.y = -800
	box.position.y = -200
	
	var tween = create_tween()
	tween.tween_property(
		box,
		"position:y",
		0,
		0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		strand,
		"position:y",
		0,
		1.0
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): 
		finished_animation = true
	)

func on_area_entered(area):
	if !(area.owner is PlayerController) or !finished_animation:
		return
	
	var player = area.owner as PlayerController
	
	player.can_move = false
	player.state = player.State.IDLE
	
	var tween = create_tween()
	
	tween.tween_property(player, "global_position", pos.global_position, 0.2)
	tween.tween_callback(func():
		hand1.show()
		player.hide()
		player_animation.show()
	)
	tween.tween_interval(1.0)
	tween.tween_property(strand, "position:y", -200, 1.0)
	tween.tween_callback(func(): hand2.show())
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		var origin = pos.global_position
		origin.y -= 300
		CircleTransition.reload_scene(origin, Vector2(960, 540))
	)
	tween.tween_property(strand, "position:y", -800, 2.0)
	
