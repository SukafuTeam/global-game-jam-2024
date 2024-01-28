extends Enemy

enum State { MOVE, SEARCH, DAMAGE }

@onready var body_container: Node2D = $BodyContainer
@onready var body: Sprite2D = $BodyContainer/Body
@onready var eyes: Sprite2D = $BodyContainer/Body/Eyes

@export_subgroup("Movement Fields")
@export var move_speed: float = 100.0
@export var move_accel: float = 2.0
@export var move_time: float = 4.0
var move_direction: Vector2
@export var recoil_impulse: float = 400.0
@export var recoil_damp: float = 15
@export var recoil_time: float = 0.3
@export var swing_speed: float = 5
@export var swing_force: float = 3
@export var blink_times: int = 4

@export_subgroup("Visual Fields")
var time: float
var flash_intensity: float
@export var down_texture: Texture
@export var up_texture: Texture

@export var deny_sfx: AudioStream

var tween: Tween

var state: State:
	set(value):
		if value != state:
			enter_state(value)
		state = value
	get:
		return state
var current_state_time: float

func _ready():
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
			state = handle_move(delta)
		State.SEARCH:
			state = handle_chase(delta)
		State.DAMAGE:
			state = handle_damage(delta)

	move_and_slide()
	
func handle_move(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.SEARCH
	
	velocity = velocity.move_toward(move_direction * move_speed, move_accel)
	
	return State.MOVE

func handle_chase(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.MOVE
	
	velocity = Vector2.ZERO
	
	return State.SEARCH
	
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
	
	var should_hit = false
	var dir = attacker_position - global_position
	if move_direction.x > 0 and move_direction.y > 0:
		should_hit = !(dir.x > 0 and dir.y > 0)
	elif move_direction.x < 0 and move_direction.y > 0:
		should_hit = !(dir.x < 0 and dir.y > 0)
	elif move_direction.x > 0 and move_direction.y < 0:
		should_hit = !(dir.x > 0 and dir.y < 0)
	elif move_direction.x < 0 and move_direction.y < 0:
		should_hit = !(dir.x < 0 and dir.y < 0)
		
	if should_hit:
		health -= damage
		flash_intensity = 1.0
		var tween = create_tween()
		tween.tween_property(
			self,
			"flash_intensity",
			0.0,
			current_state_time
		).set_ease(Tween.EASE_OUT)
		SoundController.play_sfx(damage_sound, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	else:
		SoundController.play_sfx(deny_sfx, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		
	
	var hit_direction = (attacker_position - global_position).normalized()
	current_state_time = recoil_time
	velocity = -hit_direction * recoil_impulse
	state = State.DAMAGE
	

func enter_state(new_state):
	match new_state:
		State.DAMAGE:
			if tween != null and tween.is_valid():
				tween.kill()
			eyes.hide()
		State.SEARCH:
			var time_open = randf_range(0.3, 0.6)
			var time_close = randf_range(0.1, 0.2)
			
			current_state_time = 0.1 + (time_open * blink_times) + (time_close * blink_times)
			move_direction.y = 1
			
			if tween != null and tween.is_valid():
				tween.kill()
			
			tween = create_tween()
			tween.tween_property(body, "rotation_degrees", 0, 0.1)
			for i in blink_times:
				tween.tween_callback(func(): eyes.show())
				tween.tween_interval(time_close)
				tween.tween_callback(func(): eyes.hide())
				tween.tween_interval(time_open)
			
			time = 0
		State.MOVE:
			current_state_time = move_time
			
			var target = get_global_mouse_position()
			if Global.player != null:
				target = Global.player.global_position
			
			move_direction = (target - global_position).normalized()

func update_sprite(delta):
	if abs(move_direction.x) > 0.1:
		body_container.scale.x = 1 if move_direction.x >=0 else -1
	
	if move_direction.y >= 0:
		body.texture = down_texture
	else:
		body.texture = up_texture
		
func update_offset(delta):
	if state != State.MOVE:
		return
	
	time += delta
	var angle = sin(time * swing_speed) * swing_force
	body.rotation_degrees = angle
