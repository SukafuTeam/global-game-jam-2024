extends CharacterBody2D
class_name PlayerController

enum State { IDLE, WALK, DASH, ATTACK, DAMAGE }

@onready var body: Node2D = $BodyContainer
@onready var animation_body: Node2D = $BodyContainer/PlayerAnimation
@onready var animation: AnimationPlayer = $BodyContainer/PlayerAnimation/Animations
@onready var animation_up: Node2D = $BodyContainer/PlayerAnimation/Sprites/Up
@onready var animation_down: Node2D = $BodyContainer/PlayerAnimation/Sprites/Down
@onready var player_animator: PlayerAnimator = $BodyContainer/PlayerAnimation

@onready var walk_particle: CPUParticles2D = $WalkParticle
@onready var damage_particle: CPUParticles2D = $DamageParticle

@onready var hitbox: Area2D = $Hitbox


@export_subgroup("Movement Fields")
@export var move_accel: float = 100.0
@export var move_speed: float = 400.0
var can_move: bool

@export_subgroup("Dash Fields")
@export var dash_speed: float = 1200.0
@export var dash_time: float = 0.15

@export_subgroup("Attack Fields")
@export var weapon: Weapon
@export var attack_move_speed: float = 200.0
@export var secondary: SecondaryItem
var can_secondary: bool:
	get:
		if secondary == null:
			return false
		return secondary.can_use()

@export_subgroup("State Fields")
var state: State:
	set(value):
		if value != state:
			exit_state(state)
			enter_state(value)
		
		state = value
	get:
		return state
var last_input: Vector2
var current_state_time: float = 0.0
var current_damage_cooldown: float

@export_subgroup("Combat Fields")
@export var recoil_speed: float = 1200.0
@export var recoil_time: float = 0.4
@export var damage_cooldown_time: float = 2.0
var recoil_direction: Vector2
var flash_intensity: float

@export_subgroup("Sound Fields")
@export var dash_effect: AudioStream
@export var step_effect: AudioStream
@export var attack_effect: AudioStream
@export var damage_effect: AudioStream
@export var secondary_effect: AudioStream

@export var attack_buffer_time: float = 0.1
var current_attack_buffer_time: float


var time_dead: float

func _ready():
	can_move = true
	Global.player = self
	animation.playback_default_blend_time = 0.1
	
	current_attack_buffer_time = -1
	
	player_animator.footstep.connect(func():
		SoundController.play_sfx(step_effect, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	)
	
	Global.equip_weapon(Global.weapon_index)
	Global.equip_secondary(Global.secondary_index)


func _process(delta):
	current_attack_buffer_time -= delta
	
	if Global.health == 0:
		time_dead += delta
		last_input = Vector2(1,1)
		if time_dead < 3:
			return
		
		if Input.is_action_just_pressed("attack"):
			animation.process_mode = Node.PROCESS_MODE_DISABLED
			Global.reset_stats()
			Transition.change_scene("res://scenes/menu_scene.tscn")
			return
	update_animation()
	check_damage(delta)
	walk_particle.emitting = velocity.length() > move_accel * 0.95
	
	if Input.is_action_just_pressed("attack"):
		current_attack_buffer_time = attack_buffer_time

func _physics_process(delta):
	if !can_move:
		last_input = Vector2(1, 1)
		return
	else:
		match state:
			State.IDLE:
				state = handle_idle()
			State.WALK:
				state = handle_walk()
			State.DASH:
				state = handle_dash(delta)
			State.ATTACK:
				state = handle_attack()
			State.DAMAGE:
				state = handle_damage(delta)

	move_and_slide()

func handle_idle() -> State:
	var input = Input.get_vector("left", "right", "up", "down")
	
	if input.length() > 0.05:
		last_input = input
		return State.WALK
	
	if Input.is_action_just_pressed("dash"):
		return State.DASH
		
	if current_attack_buffer_time >= 0.0 and can_attack():
		return State.ATTACK
		
	if Input.is_action_just_pressed("item") and can_secondary:
		secondary.use(global_position)
		SoundController.play_sfx(secondary_effect, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		
	
	velocity = velocity.move_toward(Vector2.ZERO, move_accel * 2)
	
	return State.IDLE
	
func handle_walk() -> State:
	var input = Input.get_vector("left", "right", "up", "down")
	
	if input.length() < 0.05:
		return State.IDLE
	else:
		last_input = input
		
	if Input.is_action_just_pressed("dash"):
		return State.DASH
	
	if current_attack_buffer_time >= 0.0 and can_attack():
		return State.ATTACK
		
	if Input.is_action_just_pressed("item") and can_secondary:
		secondary.use(global_position)
		
	velocity = velocity.move_toward(input * move_speed, move_accel)
	
	return State.WALK

func handle_dash(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.IDLE
	
	velocity = last_input.normalized() * dash_speed
	
	return State.DASH
	
func handle_attack() -> State:
	if weapon == null:
		return State.IDLE
	
	if weapon.finished_attack():
		return State.IDLE
	
	var areas = weapon.get_areas()
	
	for area in areas:
		if area.owner is Enemy:
			var enemy = area.owner as Enemy
			enemy.take_damage(Global.player_damage, global_position)
			weapon.hit_something()
		if area.owner is Chest:
			var chest = area.owner as Chest
			chest.open()
			weapon.hit_something()
		
	
	velocity = weapon.get_move_velocity()
	
	return State.ATTACK
	
func handle_damage(delta):
	current_state_time -= delta
	if current_state_time <= 0.0:
		if Global.health == 0:
			velocity = Vector2.ZERO
			can_move = false
			animation_down.show()
			animation_up.hide()
			animation.play("death_down")
			return State.DAMAGE
		return State.IDLE
	
	if current_state_time > recoil_time * 0.3:
		velocity = Vector2.ZERO
		get_viewport().get_camera_2d().offset = Vector2(
			randf_range(-10, 10),
			randf_range(-5, 5)
		)
	else:
		velocity = recoil_direction.normalized() * recoil_speed
		get_viewport().get_camera_2d().offset = Vector2.ZERO
	
	return State.DAMAGE

func enter_state(new_state):
	match new_state:
		State.IDLE:
			player_animator.set_idle()
		State.DASH:
			player_animator.set_strength()
			current_state_time = dash_time
			SoundController.play_sfx(
				dash_effect,
				randf_range(0.9, 1.1),
				randf_range(0.9, 1.1)
			)
		State.ATTACK:
			if weapon == null:
				push_warning("Trying to attack with a null weapon")
				return
			weapon.attack(last_input)
			player_animator.set_strength()
			if !(weapon is DrillWeapon):
				SoundController.play_sfx(attack_effect, randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		State.DAMAGE:
			player_animator.set_pain()
			current_state_time = recoil_time
			#flash_intensity = 1.0
			var tween = create_tween()
			tween.tween_property(self, "flash_intensity", 0.0, recoil_time)

func exit_state(current_state):
	match current_state:
		State.ATTACK:
			if weapon == null:
				return
			weapon.finish_attack()
		State.DAMAGE:
			flash_intensity = 0.0
	
func can_attack() -> bool:
	if weapon == null:
		return false
	
	return weapon.can_attack()

func update_animation():
	animation_body.material.set_shader_parameter("flash_intensity", flash_intensity)
	
	if Global.health == 0:
		return
	
	if last_input.length() < 0.05:
		return
	
	if abs(last_input.x) > 0.1:
		body.scale.x = 1 if last_input.x >= 0 else -1
	
	animation_up.visible = false
	animation_down.visible = false
	
	var animation_suffix = "_down"
	if last_input.y < -0.05:
		animation_suffix = "_up"
		animation_up.visible = true
	else:
		animation_down.visible = true
		
	var animation_prefix = "idle"
	
	animation.speed_scale = 1.0
	match state:
		State.WALK:
			animation_prefix = "run"
			var speed_percent = inverse_lerp(0, move_speed, velocity.length())
			speed_percent = clamp(speed_percent, 0.5, 1.0)
			animation.speed_scale = 3.0 * speed_percent
		State.DASH:
			animation_prefix = "dash"
		State.DAMAGE:
			animation_prefix = "attack"
		State.ATTACK:
			animation_prefix = "attack"
	
	var animation_name = animation_prefix + animation_suffix
	
	if animation.current_animation.get_basename() != animation_name or animation.current_animation.get_basename() == "":
		animation.play(animation_name)
	
	
func check_damage(delta):
	if Global.health == 0:
		return
	
	if current_damage_cooldown > 0.0:
		current_damage_cooldown -= delta
		animation_body.modulate.a = 0.5
	else:
		animation_body.modulate.a = 1.0
	
	if state == State.DASH or current_damage_cooldown > 0.0:
		hitbox.hide()
		return
	
	hitbox.show()
	
	var areas = hitbox.get_overlapping_areas()
	for area in areas:
		if area.owner is Enemy or area is Projectile:
			
			SoundController.play_sfx(damage_effect)
			
			var should_hurt = true
			if secondary != null:
				if secondary is ShieldItem:
					var shield = secondary as ShieldItem
					if shield.active:
						shield.used()
						should_hurt = false
					
			if should_hurt:
				Global.health -= 1
			
			var tween = create_tween()
			var camera = get_viewport().get_camera_2d()
			var original = Vector2.ONE
			var target = Vector2.ONE * 2.0
			
			tween.tween_property(
				camera,
				"zoom",
				target,
				0.2
			).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
			tween.tween_property(
				camera,
				"zoom",
				original,
				0.5
			)
			
			current_damage_cooldown = damage_cooldown_time
			state = State.DAMAGE
			recoil_direction = global_position - area.global_position
			damage_particle.look_at(damage_particle.global_position + recoil_direction)
			damage_particle.emitting = true
			last_input = -recoil_direction.normalized()
			return
			

