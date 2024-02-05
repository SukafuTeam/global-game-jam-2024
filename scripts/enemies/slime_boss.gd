extends Enemy
class_name SlimeBoss

signal dead

enum State { MOVE, PREP, DASH }

@onready var body: Sprite2D = $BodyContainer/Body
@onready var eye_center = $BodyContainer/EyeCenter
@onready var mouth: Sprite2D = $BodyContainer/Body/Mouth
@onready var health_boss: HealthBoss = $HealthBoss


@export var move_speed_range: Vector2 = Vector2(30, 100)
var move_speed: float:
	get:
		var health_percent = inverse_lerp(0, initial_health, health)
		return lerp(move_speed_range.y, move_speed_range.x, health_percent)

@export var move_accel: float = 10.0

@export var minimum_scale: float = 0.2

@export var body_texture: Texture
@export var eyes: Array[Sprite2D]

@export var idle_mouth: Texture
@export var damage_mouth: Texture

@export var spawn_slime_range: Vector2 = Vector2(5.0, 1.0)
var current_slime_spawn_cooldown: float
@export var weak_slime: PackedScene
@export var strong_slime: PackedScene

var initial_health: int

var flash_intensity: float

@export var damage_cooldown: float = 0.3
var current_damage_cooldown: float 

var state: State:
	set(value):
		state = value
	get:
		return state


func _ready():
	initial_health = health
	current_slime_spawn_cooldown = spawn_slime_range.x
	health_boss.setup(health)
	
	body.material.set_shader_parameter("color", Color(0.77, 0.65, 0.09))
	flash_intensity = 1.0
	
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func():
		body.material.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	)

func _process(delta):
	current_damage_cooldown -= delta
	update_sprite()
	check_spawn(delta)

func _physics_process(_delta):
	match state:
		State.MOVE:
			state = handle_move()

	move_and_slide()

func handle_move() -> State:
	
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
	
	var dir = target - global_position
	
	velocity = velocity.move_toward(dir.normalized() * move_speed, move_accel)
	
	return State.MOVE
	
func update_sprite():
	
	body.material.set_shader_parameter("flash_intensity", flash_intensity)
	
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
		
	var angle = rad_to_deg(eye_center.get_angle_to(target))
	
	for eye in eyes:
		eye.rotation_degrees = angle
	
	mouth.texture = idle_mouth if current_damage_cooldown <= 0.0 else damage_mouth

func take_damage(damage: int, _attacker_position: Vector2):
	if current_damage_cooldown >= 0:
		return
	
	flash_intensity = 1.0
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, 0.3)
	current_damage_cooldown = damage_cooldown
	
	health -= damage
	health_boss.update_health(health)
	
	SoundController.play_sfx(damage_sound, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	
	var health_percent = inverse_lerp(0, initial_health, health)		 
	scale = Vector2(
		lerp(minimum_scale, 1.0, health_percent),
		lerp(minimum_scale, 1.0, health_percent)
	)
	
	if health <= 0:
		WhiteFade.fade_in()
		dead.emit()
		queue_free()

func check_spawn(delta):
	current_slime_spawn_cooldown -= delta
	
	if current_slime_spawn_cooldown > 0.0:
		return
		
	var child = weak_slime
	if health < initial_health/2:
		child = strong_slime
	
	var sce = child.instantiate()
	add_child(sce)
	sce.global_position = global_position + Vector2(0, 100)
	
	var health_percent = inverse_lerp(0, initial_health, health)		 
	current_slime_spawn_cooldown = lerp(spawn_slime_range.x, spawn_slime_range.y, health_percent)
	
