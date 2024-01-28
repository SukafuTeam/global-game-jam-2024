class_name Enemy
extends CharacterBody2D

@export var health: int
@export var death_color: Color

@export var damage_sound: AudioStream = preload("res://sounds/sfx/enemy_damage.ogg")

func _enter_tree():
	Global.add_enemy()

func take_damage(damage: int, attacker_position: Vector2):
	pass
	
func _exit_tree():
	Global.remove_enemy()
