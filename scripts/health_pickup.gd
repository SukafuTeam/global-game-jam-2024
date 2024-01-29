extends Node2D

@onready var particle: CPUParticles2D = $Health/CPUParticles2D

@onready var sprite: Sprite2D = $Health
@onready var area: Area2D = $Area2D

@export var pickup_sfx: AudioStream

var time: float

func _ready():
	area.area_entered.connect(func(other_area):
		if!(other_area.owner is PlayerController):
			return
		
		SoundController.play_sfx(pickup_sfx)
		
		if Global.health < 5:
			Global.health += 1

		queue_free()
	)
	
	particle.emitting = false
	sprite.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func(): particle.emitting = true)

func _process(delta):
	time += delta
	sprite.position.y = sin(time * 2) * 20
