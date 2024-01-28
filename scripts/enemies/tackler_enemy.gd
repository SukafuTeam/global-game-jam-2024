class_name TacklerEnemy
extends Enemy

enum State { WALK, PREP, DASH, DAMAGE }

@onready var body_container: Node2D = $BodyContainer
@onready var body: Sprite2D = $BodyContainer/Body

@export_subgroup("Movement Fields")
@export var move_speed: float = 100.0
@export var move_accell: float = 10.0
@export var recoil_impulse: float = 500.0
@export var recoil_damp: float = 5
@export var recoil_time: float = 0.3
var last_input: Vector2

@export_subgroup("Jump Fields")
@export var max_jump_heigh: float = 40
@export var jump_speed: float = 15
@export var jump_height_delta: float = 0.1
var current_jump_height: float = 0
var time: float

@export_subgroup("Combat Fields")
@export var tackle_time: float = 0.5
@export var tackle_move_speed: float = 500
@export var tackle_distance: float = 200
@export var tackle_cooldown: float = 2.0
@export var prep_scale: Vector2 = Vector2(1.3, 0.7)
@export var prep_time: float = 0.6
var current_tackle_cooldown: float

@export_subgroup("Visual Fields")
@export var down_move_texture: Texture
@export var down_tackle_texture: Texture
@export var up_texture: Texture
@export var scale_jump_down: Vector2 = Vector2(1.1, 0.9)
@export var scale_jump_up: Vector2 = Vector2(0.9, 1.1)
var flash_intensity: float
var initial_body_scale: Vector2

var can_attack: bool:
	get:
		return current_tackle_cooldown <= 0.0

var state: State:
	set(value):
		if state != value:
			enter_state(value)
		state = value
	get:
		return state
var current_state_time: float

func _ready():
	initial_body_scale = body.scale
	
	body.material.set_shader_parameter("color", Color(0.77, 0.65, 0.09))
	flash_intensity = 1.0
	
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, 1.0)
	tween.tween_callback(func():
		body.material.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	)
	

func _process(delta):
	body.material.set_shader_parameter("flash_intensity", flash_intensity)
	if current_tackle_cooldown > 0:
		current_tackle_cooldown -= delta
	update_sprite()
	update_jump(delta)

func _physics_process(delta):
	
	current_tackle_cooldown -= delta
	
	match state:
		State.WALK:
			state = handle_walk()
		State.PREP:
			state = handle_prep(delta)
		State.DASH:
			state = handle_dash(delta)
		State.DAMAGE:
			state = handle_damage(delta)

	move_and_slide()
	
func handle_walk() -> State:
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
		
	var dir = target - global_position
	last_input = dir.normalized()
	
	if dir.length() <= tackle_distance and can_attack:
		last_input = dir.normalized()
		return State.PREP

	velocity = velocity.move_toward(dir.normalized() * move_speed, move_accell)
	
	return State.WALK
	
func handle_prep(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.DASH
	
	return State.PREP

func handle_dash(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.WALK
	
	velocity = last_input.normalized() * tackle_move_speed
	
	return State.DASH
	
func handle_damage(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		if health <= 0:
			Global.spawn_enemy_death(global_position, death_color)
			queue_free()
		
		flash_intensity = 0.0
		body.material.set_shader_parameter("flash_intensity", flash_intensity)
		return State.WALK
	
	body.material.set_shader_parameter("flash_intensity", flash_intensity)
	velocity = velocity.move_toward(Vector2.ZERO, recoil_damp)
	
	return State.DAMAGE
	

func enter_state(new_state: State):
	match new_state:
		State.PREP:
			velocity = Vector2.ZERO
			current_state_time = prep_time * randf_range(0.8, 1.2)
			var tween = create_tween()
			var target_y = initial_body_scale.y * prep_scale.y
			tween.tween_property(body, "scale:y", target_y, current_state_time * 0.8)
		State.DASH:
			current_tackle_cooldown = tackle_cooldown
			current_state_time = tackle_time * randf_range(0.9, 1.1)
			var tween = create_tween()
			tween.tween_property(body, "scale", initial_body_scale, current_state_time * 0.4)
		State.DAMAGE:
			current_state_time = recoil_time * randf_range(0.8, 1.2)
				
			velocity = -last_input.normalized() * recoil_impulse
			
			flash_intensity = 1.0
			var tween = create_tween()
			tween.tween_property(
				self,
				"flash_intensity",
				0.0,
				current_state_time
			).set_ease(Tween.EASE_OUT)


func update_sprite():
	if abs(last_input.x) > 0.1:
		body_container.scale.x = 1
		if last_input.x < 0:
			body_container.scale.x = -1
	
	if abs(last_input.y) > 0.1:
		if last_input.y < 0:
			body.texture = up_texture
		elif state == State.WALK:
			body.texture = down_move_texture
		else:
			body.texture = down_tackle_texture

func update_jump(delta):
	if state != State.WALK:
		body.position = Vector2.ZERO
		body.scale = initial_body_scale
		return
	
	time += delta
	var base_height = ((sin(time * jump_speed) + 1.0) / 2.0) * max_jump_heigh
	var speed_percent = inverse_lerp(0, move_speed, velocity.length())
	var target_jump_height = base_height * speed_percent
	current_jump_height = lerp(current_jump_height, target_jump_height, jump_height_delta)
	body.position = Vector2(0, -current_jump_height)
	
	
	var jump_heigth_percent = inverse_lerp(0, current_jump_height, base_height)
	jump_heigth_percent = clamp(jump_heigth_percent, 0, 1)
	var scale_x = lerp(scale_jump_down.x, scale_jump_up.x, jump_heigth_percent)
	var scale_y = lerp(scale_jump_down.y, scale_jump_up.y, jump_heigth_percent)
	body.scale = initial_body_scale * Vector2(scale_x, scale_y)

func take_damage(damage: int, attacker_position: Vector2):
	if state == State.DAMAGE:
		return
	
	health -= damage
	last_input = (attacker_position - global_position).normalized()
	state = State.DAMAGE
	
	SoundController.play_sfx(damage_sound, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
