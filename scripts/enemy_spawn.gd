extends Node2D
class_name EnemySpawner

signal finished

@onready var particle: CPUParticles2D = $Particle

@export var enemy: PackedScene

# Called when the node enters the scene tree for the first time.
func setup():
	var wait_time = randf_range(0.1, 1.0)
	await get_tree().create_timer(wait_time).timeout
	
	particle.emitting = true

	await particle.finished
	
	if enemy != null:
		var instance = enemy.instantiate()
		get_parent().add_child(instance)
		instance.global_position = particle.global_position
	
	finished.emit()
	queue_free()
