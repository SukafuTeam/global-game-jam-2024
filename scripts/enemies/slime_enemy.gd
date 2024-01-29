class_name SlimeEnemy
extends Enemy

enum State { MOVE, BREATH, DAMAGE }

@onready var body_container: Node2D = $BodyContainer
@onready var body: Sprite2D = $BodyContainer/Body

@export_subgroup("Movement Fields")
@export var move_speed: float = 100.0
@export var move_accel: float = 2.0
@export var move_time: float = 1.0
@export var breath_time: float = 0.5
@export var recoil_impulse: float = 500.0
@export var recoil_damp: float = 5
@export var recoil_time: float = 0.3

@export var final_scale_move: Vector2 = Vector2(1.5, 0.8)
@export var final_scale_breath: Vector2 = Vector2.ONE
var initial_body_scale: Vector2

@export_subgroup("Visual Fields")
@export var look_down_texture: Texture
@export var look_up_texture: Texture
var flash_intensity: float

var state: State:
	set(value):
		if value != state:
			enter_state(value)
		state = value
	get:
		return state
var current_state_time: float
var tween: Tween
var move_direction: Vector2 = Vector2.RIGHT

func _ready():
	initial_body_scale = body.scale
	
	body.material.set_shader_parameter("color", Color(0.77, 0.65, 0.09))
	flash_intensity = 1.0
	
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "flash_intensity", 0.0, 1.0)
	flash_tween.tween_callback(func():
		body.material.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	)

func _process(_delta):
	update_animation()
	body.material.set_shader_parameter("flash_intensity", flash_intensity)

func _physics_process(delta):
	match state:
		State.MOVE:
			state = handle_move(delta)
		State.BREATH:
			state = handle_breath(delta)
		State.DAMAGE:
			state = handle_damage(delta)
	move_and_slide()
	
func handle_move(delta) -> State:
	current_state_time -= delta
	if current_state_time < 0.0:
		return State.BREATH
	
	velocity = velocity.move_toward(move_direction.normalized() * move_speed, move_accel)
	
	return State.MOVE

func handle_breath(delta) -> State:
	current_state_time -= delta
	if current_state_time < 0.0:
		return State.MOVE
	
	velocity = Vector2.ZERO
	
	return State.BREATH

func handle_damage(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		if health <= 0:
			Global.spawn_enemy_death(global_position, death_color)
			queue_free()
		
		flash_intensity = 0.0
		body.material.set_shader_parameter("flash_intensity", flash_intensity)
		return State.BREATH
	
	body.material.set_shader_parameter("flash_intensity", flash_intensity)
	velocity = velocity.move_toward(Vector2.ZERO, recoil_damp)
	
	return State.DAMAGE

func enter_state(new_state):
	match new_state:
		State.MOVE:
			current_state_time = move_time * randf_range(0.8, 1.2)
			
			var target = get_global_mouse_position()
			if Global.player != null:
				target = Global.player.global_position
			move_direction = target - global_position
			
			if tween != null and tween.is_valid():
				tween.kill()
			
			var target_scale = initial_body_scale * final_scale_move
			tween = create_tween()
			tween.tween_property(
				body,
				"scale",
				target_scale,
				current_state_time
			)
			return
		State.BREATH:
			current_state_time = breath_time * randf_range(0.8, 1.2)
			if tween != null and tween.is_valid():
				tween.kill()
			
			var target_scale = initial_body_scale * final_scale_breath
			tween = create_tween()
			tween.tween_property(
				body,
				"scale",
				target_scale,
				current_state_time
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
			return
		State.DAMAGE:
			current_state_time = recoil_time * randf_range(0.8, 1.2)
			if tween != null and tween.is_valid():
				tween.kill()
				
			velocity = -move_direction.normalized() * recoil_impulse
			
			flash_intensity = 1.0
			tween = create_tween()
			tween.tween_property(
				self,
				"flash_intensity",
				0.0,
				current_state_time
			).set_ease(Tween.EASE_OUT)
			body.scale = initial_body_scale

func take_damage(damage: int, attacker_position: Vector2):
	if state == State.DAMAGE:
		return
	
	health -= damage
	move_direction = (attacker_position - global_position).normalized()
	state = State.DAMAGE

	body.material.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	SoundController.play_sfx(damage_sound, randf_range(0.9, 1.1), randf_range(0.9, 1.1))

func update_animation():
	if abs(move_direction.x) > 0.1:
		body_container.scale.x = 1 if move_direction.x >= 0 else -1
	
	if abs(move_direction.y) > 0.1:
		body.texture = look_down_texture if move_direction.y >=0 else look_up_texture
