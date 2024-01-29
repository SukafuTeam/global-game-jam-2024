class_name PokeWeapon
extends Weapon

@onready var sprite_root: Node2D = $SpriteRoot
@onready var hurtbox: Area2D = $SpriteRoot/HurtBox
@onready var spear: Sprite2D = $SpriteRoot/Spear

@export var cooldown_time: float = 0.1
@export var attack_move_speed: float = 600.0
@export var recoild_move_speed: float = 200.0
@export var attack_time: float = 0.2
@export var hurt_range: Vector2 = Vector2(0.4, 0.6)

@export var attack_ease_type: Tween.EaseType = Tween.EASE_OUT
@export var attack_trans_type: Tween.TransitionType = Tween.TRANS_EXPO

@export var start_spear_offset: float = 130.0
@export var end_spear_offset: float = 200

@export var initial_texture: Texture
@export var final_texture: Texture
@export var texture_threshold: float = 0.6

var tween: Tween
var attack_direction: Vector2
var current_cooldown_time: float
var current_attack_time: float
var on_recoil: bool


func _ready():
	sprite_root.hide()

func _process(delta):
	current_cooldown_time -= delta
	if current_attack_time > 0.0:
		current_attack_time -= delta
	
	var current_attack_percent = inverse_lerp(0, attack_time, current_attack_time)
	if current_attack_percent < texture_threshold:
		spear.texture = final_texture

func can_attack() -> bool:
	return current_cooldown_time <= 0.0
	
func attack(direction: Vector2):
	spear.texture = initial_texture
	attack_direction = direction
	current_attack_time = attack_time
	on_recoil = false
	sprite_root.show()
	sprite_root.look_at(global_position + direction)
	hurtbox.hide()

	if tween != null and tween.is_valid():
		tween.kill()
	
	spear.position.x = start_spear_offset
	tween = create_tween()
	tween.tween_property(
		spear,
		"position:x",
		end_spear_offset,
		attack_time * 0.7
	).set_ease(attack_ease_type).set_trans(attack_trans_type)
	tween.tween_property(
		spear,
		"position:x",
		start_spear_offset,
		attack_time * 0.3
	).set_ease(attack_ease_type).set_trans(attack_trans_type)
	
func get_move_velocity() -> Vector2:
	if on_recoil:
		return -attack_direction.normalized() * recoild_move_speed
	
	return attack_direction.normalized() * attack_move_speed

func hit_something():
	on_recoil = true

func get_areas():
	var current_attack_percent = inverse_lerp(0, attack_time, current_attack_time)
	if current_attack_percent < hurt_range.x or current_attack_percent > hurt_range.y:
		hurtbox.hide()
		return []
	
	hurtbox.show()
	return hurtbox.get_overlapping_areas()

func finished_attack():
	if tween == null:
		return true
	
	return !tween.is_running()

func finish_attack():
	current_cooldown_time = cooldown_time
	sprite_root.hide()
	if tween != null and tween.is_valid():
		tween.kill()
