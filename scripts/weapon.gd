class_name Weapon
extends Node2D

@export var data: WeaponData

func can_attack() -> bool:
	return false
	
func attack(direction: Vector2):
	pass
	
func get_move_velocity() -> Vector2:
	return Vector2.ZERO

func hit_something():
	pass

func get_areas():
	pass

func finished_attack():
	pass

func finish_attack():
	pass

