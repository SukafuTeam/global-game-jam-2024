extends Enemy

enum State { MOVE, DAMAGE }

@onready var body_container: Node2D = $BodyContainer
@onready var body: Sprite2D = $BodyContainer/Body

@export_subgroup("Movement Fields")
@export var move_speed: float = 100.0
@export var move_accel: float = 2.0
var last_direction: Vector2
@export var recoil_impulse: float = 400.0
@export var recoil_damp: float = 15
@export var recoil_time: float = 0.3

@export_subgroup("Visual Fields")
@export var fly_amplitude: float = 10
@export var fly_speed: float = 10
var initial_offset: float
var time: float
var flash_intensity: float
@export var down_textures: Array[Texture]
@export var up_textures: Array[Texture]
var current_texture_index: int
@export var change_texture_time: float = 0.05
var current_texture_time: float

var state: State
var current_state_time: float

func _ready():
	initial_offset = body.position.y
	fly_amplitude *= randf_range(0.9, 1.1)
	fly_speed *= randf_range(0.8, 1.2)
	change_texture_time *= randf_range(0.8, 1.2)
	
	body.material.set_shader_parameter("color", Color(0.77, 0.65, 0.09))
	flash_intensity = 1.0
	
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, 1.0)
	tween.tween_callback(func():
		body.material.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	)

func _process(delta):
	update_sprite(delta)
	update_offset(delta)
	body.material.set_shader_parameter("flash_intensity", flash_intensity)

func _physics_process(delta):
	
	match state:
		State.MOVE:
			state = handle_move()
		State.DAMAGE:
			state = handle_damage(delta)

	move_and_slide()
	
func handle_move() -> State:
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
	
	var dir = target - global_position
	last_direction = dir
	
	velocity = velocity.move_toward(dir.normalized() * move_speed, move_accel)
	
	return State.MOVE
	
func handle_damage(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		if health <= 0:
			Global.spawn_enemy_death(global_position, death_color)
			queue_free()
		
		flash_intensity = 0.0
		body.material.set_shader_parameter("flash_intensity", flash_intensity)
		return State.MOVE
	
	body.material.set_shader_parameter("flash_intensity", flash_intensity)
	velocity = velocity.move_toward(Vector2.ZERO, recoil_damp)
	
	return State.DAMAGE
	
func take_damage(damage: int, attacker_position: Vector2):
	if state == State.DAMAGE:
		return
	
	health -= damage
	last_direction = (attacker_position - global_position).normalized()
	current_state_time = recoil_time
	velocity = -last_direction * recoil_impulse
	state = State.DAMAGE
	
	SoundController.play_sfx(damage_sound, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	
	flash_intensity = 1.0
	var tween = create_tween()
	tween.tween_property(
		self,
		"flash_intensity",
		0.0,
		current_state_time
	).set_ease(Tween.EASE_OUT)

func update_sprite(delta):
	
	current_texture_time += delta
	
	if current_texture_time >= change_texture_time:
		current_texture_index = (current_texture_index + 1) % 2
		current_texture_time = 0
	
	if abs(last_direction.x) > 0.1:
		body_container.scale.x = 1 if last_direction.x >=0 else -1
	
	if last_direction.y >= 0:
		body.texture = down_textures[current_texture_index]
	else:
		body.texture = up_textures[current_texture_index]
		
func update_offset(delta):
	time += delta
	
	var offset = ((sin(time * fly_speed) + 1.0) / 2.0) * fly_amplitude
	body.position.y = initial_offset + offset
