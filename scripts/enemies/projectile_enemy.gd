extends Enemy

enum State { MOVE, ATTACK, DAMAGE }

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
var initial_scale: Vector2

@export var down_idle_texture: Texture
@export var down_shoot_texture: Texture
@export var up_texture: Texture

@export_subgroup("Combat Fields")
@export var shoot_distance: float = 300
@export var inhale_time: float =  0.6
@export var exhale_time: float = 0.6
@export var inhale_scale: float = 1.5
@export var projectile: PackedScene
@export var attack_cooldown: float = 2.0
var current_attack_cooldown: float
@onready var projectile_point: Node2D = $BodyContainer/Body/ProjectTileSpawn

var tween: Tween

var state: State:
	set(value):
		if value != state:
			if tween != null and tween.is_valid():
				tween.kill()
		if value != state and value == State.ATTACK:
			var in_time = inhale_time * randf_range(0.8, 1.2)
			var out_time = exhale_time * randf_range(0.8, 1.2)
			current_state_time = in_time + out_time + 0.15
			
			tween = create_tween()
			tween.tween_property(
				body,
				"scale",
				initial_scale * inhale_scale,
				in_time
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_property(
				body,
				"scale",
				initial_scale * (inhale_scale * 0.9),
				0.05
			)
			# TODO: SPAWN PROJECTILE
			tween.tween_callback(func():
				var proj = projectile.instantiate() as Projectile
				get_parent().add_child(proj)
				proj.global_position = projectile_point.global_position
				
				var target = get_global_mouse_position()
				if Global.player != null:
					target = Global.player.global_position
				
				var dir = (target - projectile_point.global_position).normalized()
				proj.setup(dir)
			)
			tween.tween_property(
				body,
				"scale",
				initial_scale * inhale_scale,
				0.05
			)
			tween.tween_property(
				body,
				"scale",
				initial_scale,
				out_time
			)
			tween.tween_callback(func(): current_attack_cooldown = attack_cooldown)
			
		state = value
	get:
		return state
			
var current_state_time: float

func _ready():
	initial_scale = body.scale
	initial_offset = body.position.y
	fly_amplitude *= randf_range(0.9, 1.1)
	fly_speed *= randf_range(0.8, 1.2)
	
	body.material.set_shader_parameter("color", Color(0.77, 0.65, 0.09))
	flash_intensity = 1.0
	
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, 1.0)
	tween.tween_callback(func():
		body.material.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	)

func _process(delta):
	current_attack_cooldown -= delta
	update_sprite(delta)
	update_offset(delta)
	body.material.set_shader_parameter("flash_intensity", flash_intensity)

func _physics_process(delta):
	
	match state:
		State.MOVE:
			state = handle_move()
		State.DAMAGE:
			state = handle_damage(delta)
		State.ATTACK:
			state = handle_attack(delta)

	move_and_slide()
	
func handle_move() -> State:
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
	
	var dir = target - global_position
	
	last_direction = dir
	
	if dir.length() < shoot_distance and current_attack_cooldown <= 0.0:
		return State.ATTACK
	
	target = target - (dir.normalized() * shoot_distance)
	dir = target - global_position
	
	
	
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
	
func handle_attack(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.MOVE
	
	velocity = velocity.move_toward(Vector2.ZERO, move_accel)
	
	return State.ATTACK
	
func take_damage(damage: int, attacker_position: Vector2):
	if state == State.DAMAGE:
		return
	
	health -= damage
	last_direction = (attacker_position - global_position).normalized()
	current_state_time = recoil_time
	velocity = -last_direction * recoil_impulse
	state = State.DAMAGE
	
	flash_intensity = 1.0
	var tween = create_tween()
	tween.tween_property(
		self,
		"flash_intensity",
		0.0,
		current_state_time
	).set_ease(Tween.EASE_OUT)

func update_sprite(delta):
	
	if abs(last_direction.x) > 0.1:
		body_container.scale.x = 1 if last_direction.x >=0 else -1
	
	if last_direction.y >= 0:
		if state == State.ATTACK:
			body.texture = down_shoot_texture
		else:
			body.texture = down_idle_texture
	else:
		body.texture = up_texture
		
func update_offset(delta):
	if state == State.ATTACK:
		return 
		
		
	time += delta
	
	var offset = ((sin(time * fly_speed) + 1.0) / 2.0) * fly_amplitude
	body.position.y = initial_offset + offset
	
	
	
	var scale = sin(time * (fly_speed / 1.5) + 2.0 / 2.0) * 1.5
	body.scale = Vector2(
		initial_scale.x + (scale * 0.01),
		initial_scale.y + (scale * 0.05),
	)
