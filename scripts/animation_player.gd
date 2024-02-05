extends Node2D
class_name PlayerAnimator

signal footstep

@onready var down_face: Sprite2D = $Sprites/Down/FrenteIdle
@onready var up_face: Sprite2D = $Sprites/Up/CostasIdle

@export var down_idle_texture: Texture
@export var down_pain_texture: Texture
@export var down_strength_texture: Texture

@export var up_idle_texture: Texture
@export var up_pain_texture: Texture
@export var up_strength_texture: Texture

func on_footstep():
	footstep.emit()
	
func set_idle():
	down_face.texture = down_idle_texture
	up_face.texture = up_idle_texture

func set_pain():
	down_face.texture = down_pain_texture
	up_face.texture = up_pain_texture

func set_strength():
	down_face.texture = down_strength_texture
	up_face.texture = up_strength_texture
