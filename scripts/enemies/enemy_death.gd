class_name EnemyDeath
extends Node2D


@onready var particle: CPUParticles2D = $CPUParticles2D

func setup(enemy_color: Color):
	var color = enemy_color
	color.a = particle.color.a
	
	particle.color = color
	particle.emitting = true
	
	await particle.finished
	queue_free()
