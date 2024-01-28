class_name SwipeWeapon
extends Weapon

@onready var arc_path: Path2D = $ArcPath
@onready var arc_follow: PathFollow2D = $ArcPath/ArcFollow
@onready var trail_left: Line2D = $ArcPath/ArcFollow/Sword/TrailLeft
@onready var trail_right: Line2D = $ArcPath/ArcFollow/Sword/TrailRight
@onready var hurtbox: Area2D = $ArcPath/HurtBox

@export var zig_zag_animation: bool = true
@export var cooldown_time: float = 0.1
@export var attack_move_speed: float = 200.0
@export var recoild_move_speed: float = 100.0
@export var attack_time: float = 0.2
@export var hurt_range: Vector2 = Vector2(0.4, 0.6)

@export var attack_ease_type: Tween.EaseType = Tween.EASE_OUT
@export var attack_trans_type: Tween.TransitionType = Tween.TRANS_EXPO

var tween: Tween
var attack_direction: Vector2
var current_cooldown_time: float
var current_attack_time: float
var on_recoil: bool

func _ready():
	trail_left.hide()
	trail_right.hide()
	arc_path.hide()

func _process(delta):
	current_cooldown_time -= delta
	if current_attack_time > 0.0:
		current_attack_time -= delta
	
func can_attack() -> bool:
	return current_cooldown_time <= 0
	
func attack(direction: Vector2):
	attack_direction = direction
	current_attack_time = attack_time
	on_recoil = false
	arc_path.show()
	arc_path.look_at(global_position + direction)
	hurtbox.hide()
	
	if tween != null and tween.is_valid():
		tween.kill()
	
	var start = 0.1
	var end = 0.9
	var trail = trail_left
	
	if arc_follow.progress_ratio > 0.5 and zig_zag_animation:
		start = 0.9
		end = 0.1
		trail = trail_right
	
	arc_follow.progress_ratio = start
	trail.show()
	trail.modulate.a = 1.0
	
	tween = create_tween()
	tween.tween_property(
		arc_follow,
		"progress_ratio",
		end,
		attack_time
	).set_ease(attack_ease_type).set_trans(attack_trans_type)
	tween.parallel().tween_property(
		trail,
		"modulate:a",
		0.0,
		attack_time * 0.7
	).set_delay(attack_time * 0.3)
	
	
func get_move_velocity() -> Vector2:
	if on_recoil:
		return -attack_direction.normalized() * recoild_move_speed
	
	return attack_direction.normalized() * attack_move_speed

func get_areas():
	var current_attack_percent = inverse_lerp(attack_time, 0, current_attack_time)
	if current_attack_percent < hurt_range.x or current_attack_percent > hurt_range.y:
		hurtbox.hide()
		return []
	
	hurtbox.show()
	return hurtbox.get_overlapping_areas()

func hit_something():
	on_recoil = true
	
func finished_attack():
	if tween == null:
		return true
	
	return !tween.is_running()

func finish_attack():
	current_cooldown_time = cooldown_time
	arc_path.hide()
	if tween != null and tween.is_valid():
		tween.kill()
