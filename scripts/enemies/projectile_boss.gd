extends Enemy

signal dead

enum State { MOVE, ATTACK }

@onready var body_container: Node2D = $BodyContainer
@onready var body: Sprite2D = $BodyContainer/Body
@onready var idle_face: Sprite2D = $BodyContainer/Body/IdleFace
@onready var idle_eyes: Sprite2D = $BodyContainer/Body/IdleFace/CenterEyes/eyes
@onready var shooting_face: Sprite2D = $BodyContainer/Body/ShootingFace
@onready var damage_face: Sprite2D = $BodyContainer/Body/DamageFace
@onready var arms: Sprite2D = $BodyContainer/Arms
@onready var legs: Sprite2D = $BodyContainer/Legs
@onready var left_wing: Sprite2D = $BodyContainer/Body/LeftWing
@onready var right_wing: Sprite2D = $BodyContainer/Body/RightWing

@export_subgroup("Movement Fields")
@export var move_speed: float = 100.0
@export var move_accel: float = 2.0

@export_subgroup("Visual Fields")
@export var fly_amplitude: float = 10
@export var fly_speed: float = 5
var initial_offset: float
var time: float
var flash_intensity: float
var initial_scale: Vector2

@export_subgroup("Combat Fields")
@export var shoot_distance: float = 800
@export var inhale_time: float =  1.0
@export var exhale_time: float = 0.6
@export var inhale_scale: float = 1.2
@export var projectile: PackedScene
@export var attack_cooldown: float = 2.0
var current_attack_cooldown: float
@onready var projectile_point: Node2D = $BodyContainer/Body/ProjectTileSpawn

@export var damage_cooldown: float = 0.2
var current_damage_cooldown: float

var tween: Tween

var state: State:
	set(value):
		if value != state and value == State.ATTACK:
			var in_time = inhale_time * randf_range(0.8, 1.2)
			var out_time = exhale_time * randf_range(0.8, 1.2)
			current_state_time = in_time + out_time + 0.15 + 2.0
			current_attack_cooldown = current_state_time + attack_cooldown
			
			tween = create_tween()
			tween.tween_property(
				body_container,
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
			tween.tween_callback(spawn_projectiles)
			tween.tween_interval(1.2)
			tween.tween_property(
				body_container,
				"scale",
				initial_scale * inhale_scale,
				0.05
			)
			tween.tween_property(
				body_container,
				"scale",
				initial_scale,
				out_time
			)
			#tween.tween_callback(func(): current_attack_cooldown = attack_cooldown)
			
		state = value
	get:
		return state
			
var current_state_time: float

func spawn_projectiles():
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
	for i in 5:
		var proj = projectile.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = projectile_point.global_position
		var dir = (target - projectile_point.global_position).normalized()
		dir = dir.rotated(-deg_to_rad(60))
		proj.setup(dir)
		
		proj = projectile.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = projectile_point.global_position
		dir = (target - projectile_point.global_position).normalized()
		dir = dir.rotated(-deg_to_rad(30))
		proj.setup(dir)
		
		proj = projectile.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = projectile_point.global_position
		dir = (target - projectile_point.global_position).normalized()
		proj.setup(dir)
		
		proj = projectile.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = projectile_point.global_position
		dir = (target - projectile_point.global_position).normalized()
		dir = dir.rotated(deg_to_rad(30))
		proj.setup(dir)
		
		proj = projectile.instantiate() as Projectile
		get_parent().add_child(proj)
		proj.global_position = projectile_point.global_position
		dir = (target - projectile_point.global_position).normalized()
		dir = dir.rotated(deg_to_rad(60))
		proj.setup(dir)
		await get_tree().create_timer(0.4).timeout

func _ready():
	initial_scale = body_container.scale
	initial_offset = body.position.y
	fly_amplitude *= randf_range(0.9, 1.1)
	fly_speed *= randf_range(0.8, 1.2)
	current_attack_cooldown = 10.0
	
	material.set_shader_parameter("color", Color(0.77, 0.65, 0.09))
	flash_intensity = 1.0
	
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, 1.0)
	tween.tween_callback(func():
		material.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	)
	
	var left_tween = create_tween()
	left_tween.tween_property(left_wing, "rotation_degrees", -30, 0.05)
	left_tween.tween_property(left_wing, "rotation_degrees", 30, 0.05)
	left_tween.set_loops(-1)
	
	var right_tween = create_tween()
	right_tween.tween_property(right_wing, "rotation_degrees", 30, 0.05)
	right_tween.tween_property(right_wing, "rotation_degrees", -30, 0.05)
	right_tween.set_loops(-1)
	

func _process(delta):
	material.set_shader_parameter("flash_intensity", flash_intensity)
	current_attack_cooldown -= delta
	current_damage_cooldown -= delta
	update_sprite(delta)
	update_offset(delta)
	
	arms.position = arms.position.move_toward(body.position, 0.7)
	legs.position = legs.position.move_toward(body.position, 0.9)


func _physics_process(delta):
	
	match state:
		State.MOVE:
			state = handle_move()
		State.ATTACK:
			state = handle_attack(delta)

	move_and_slide()
	
func handle_move() -> State:
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
	
	var dir = target - global_position
	
	if dir.length() > shoot_distance and current_attack_cooldown <= 0.0:
		return State.ATTACK
	
	dir = target - global_position
	
	velocity = velocity.move_toward(dir.normalized() * move_speed, move_accel)
	
	return State.MOVE
	
func handle_attack(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.MOVE
	
	velocity = velocity.move_toward(Vector2.ZERO, move_accel)
	
	return State.ATTACK
	
func take_damage(damage: int, attacker_position: Vector2):
	if current_damage_cooldown > 0.0:
		return
	
	current_damage_cooldown = damage_cooldown
	health -= damage
	
	flash_intensity = 1.0
	var tween = create_tween()
	tween.tween_property(
		self,
		"flash_intensity",
		0.0,
		current_state_time
	).set_ease(Tween.EASE_OUT)
	
	if health <= 0:
		WhiteFade.fade_in()
		dead.emit()
		queue_free()

func update_sprite(delta):
	idle_face.visible = false
	shooting_face.visible = false
	damage_face.visible = false
	match state:
		State.MOVE:
			if current_damage_cooldown > 0:
				damage_face.visible = true
			else:
				idle_face.visible = true
		State.ATTACK:
			shooting_face.visible = true
			
	var target = get_global_mouse_position()
	if Global.player != null:
		target = Global.player.global_position
	
	var dir = (target - idle_face.global_position).normalized()
	idle_eyes.position = dir * 15
		
func update_offset(delta):
	if state == State.ATTACK:
		return 
		
	time += delta
	
	var offset = ((sin(time * fly_speed) + 1.0) / 2.0) * fly_amplitude
	body.position.y = initial_offset + offset
	
