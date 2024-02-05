extends Enemy

signal dead

enum State { WALK, DASH, DAMAGE, PREP, ATTACK }

@onready var body_container: Node2D = $BodyContainer
@onready var body: PlayerAnimator = $BodyContainer/PlayerAnimation
@onready var animation: AnimationPlayer = $BodyContainer/PlayerAnimation/Animations
@onready var look_down: Node2D = $BodyContainer/PlayerAnimation/Sprites/Down
@onready var look_up: Node2D = $BodyContainer/PlayerAnimation/Sprites/Up
@onready var damage_particle: CPUParticles2D = $DamageParticle
@onready var hitbox_col: CollisionShape2D = $hitbox/CollisionShape2D
@onready var health_boss: HealthBoss = $HealthBoss

@export var possible_weapons: Array[Weapon]
@onready var current_weapon: Weapon

@export_subgroup("Movement Fields")
@export var move_speed: float = 400.0
@export var move_accel: float = 10.0
@export var attack_distance: float = 300.0
@export var arena_center: Vector2 = Vector2(960, 660)
var last_input: Vector2
@export var dash_time: float = 0.35
@export var dash_speed: float = 1200.0
@export var dash_cooldown_time: float = 1.0
var current_dash_cooldown: float
var can_dash: bool:
	get:
		return current_dash_cooldown <= 0.0

@export var dash_into_distance: float = 600.0

@export_subgroup("Combat Fields")
@export var attack_cooldown_time: float = 0.6
var current_attack_cooldown: float
var can_attack: bool:
	get:
		if current_weapon == null:
			return false
		return current_weapon.can_attack() and current_attack_cooldown <= 0.0
@export var recoil_impulse: float = 300.0
@export var recoil_damp: float = 15
@export var recoil_time: float = 0.3
@export var prep_time: float = 0.4
var prep_tween: Tween
@export var damage_cooldown_time: float = 0.3
var current_damage_cooldown: float

@export var dash_sfx: AudioStream
@export var damage_sfx: AudioStream
@export var attack_sfx: AudioStream

var state: State:
	set(value):
		if value != state:
			exit_state(state)
			enter_state(value)
		state = value
	get:
		return state
var current_state_time: float

func _ready():
	animation.playback_default_blend_time = 0.2
	current_dash_cooldown = 3.0
	set_current_weapon()
	health_boss.setup(health)

func _process(delta):
	update_animation()
	current_attack_cooldown -= delta
	current_dash_cooldown -= delta
	current_damage_cooldown -= delta

func _physics_process(delta):

	match state:
		State.WALK:
			state = handle_walk()
		State.DASH:
			state = handle_dash(delta)
		State.DAMAGE:
			state = handle_damage(delta)
		State.PREP:
			state = handle_prep(delta)
		State.ATTACK:
			state = handle_attack(delta)
	
	move_and_slide()

func handle_walk() -> State:
	var dir = Global.player.global_position - global_position
	
	if Input.is_action_just_pressed("attack") and dir.length() <= attack_distance * 1.5 and can_dash:
		if Global.player is PlayerController:
			last_input = global_position - Global.player.global_position
			return State.DASH
		
	
	if dir.length() <= attack_distance and can_attack:
		return State.PREP
		
	if dir.length() > dash_into_distance:
		last_input = Global.player.global_position - global_position
		return State.DASH
	
	# If the player is nearby the center, stay outside from player, 
	# otherwise stay inside the arena
	var target_dir = (arena_center - Global.player.global_position).normalized()
	if (Global.player.global_position - arena_center).length() < 400:
		target_dir = (Global.player.global_position - arena_center).normalized()
	
	var target_pos = Global.player.global_position + (target_dir * attack_distance)
	
	last_input = (target_pos - global_position).normalized()
	
	velocity = velocity.move_toward(last_input * move_speed, move_accel)
	
	return State.WALK

func handle_dash(delta) -> State: 
	current_state_time -= delta
	
	if current_state_time <= 0.0:
		return State.WALK
	
	velocity = last_input.normalized() * dash_speed
	
	return State.DASH

func handle_damage(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.WALK
	
	velocity = velocity.move_toward(Vector2.ZERO, recoil_damp)
	return State.DAMAGE
	
func handle_prep(delta) -> State:
	current_state_time -= delta
	if current_state_time <= 0.0:
		return State.ATTACK
	
	var dir = Global.player.global_position - global_position
	if Input.is_action_just_pressed("attack") and dir.length() <= attack_distance * 1.5 and can_dash:
		if Global.player is PlayerController:
			#last_input = global_position - Global.player.global_position
			avoid_player()
			return State.DASH
	
	velocity = Vector2.ZERO
	
	return State.PREP

func avoid_player():
	var target_dir = (arena_center - Global.player.global_position).normalized()
	if (Global.player.global_position - arena_center).length() < 500:
		target_dir = (Global.player.global_position - arena_center).normalized()
	
	last_input = target_dir
	

func handle_attack(delta) -> State:
	if current_weapon.finished_attack():
		return State.WALK
	
	var areas = current_weapon.get_areas()
	
	for area in areas:
		if area.owner is PlayerController:
			var player = area.owner as PlayerController
			player.take_damage(global_position)
			current_weapon.hit_something()
		if area.owner is Lure:
			var l = area.owner as Lure
			l.finish()
	
	velocity = current_weapon.get_move_velocity()
	
	return State.ATTACK
	
func enter_state(new_state):
	match new_state:
		State.PREP:
			body.set_strength()
			current_state_time = prep_time
			if prep_tween != null and prep_tween.is_valid():
				prep_tween.kill()
			prep_tween = create_tween()
			body_container.scale.y = 1
			prep_tween.tween_property(body_container, "scale:y", 0.7, prep_time * 0.7)
			prep_tween.tween_property(body_container, "scale:y", 1.0, prep_time * 0.3)
		State.ATTACK:
			current_state_time = attack_cooldown_time
			last_input = (Global.player.global_position - global_position).normalized()
			body.set_strength()
			current_weapon.attack(last_input)
			SoundController.play_sfx(attack_sfx, randf_range(0.9, 1.1), randf_range(0.6, 0.8))
		State.DASH:
			current_state_time = dash_time
			body.set_strength()
			SoundController.play_sfx(dash_sfx, randf_range(0.9, 1.1), randf_range(0.6, 0.8))
			hitbox_col.disabled = true
		State.DAMAGE:
			current_state_time = recoil_time
			body.set_pain()
		State.WALK:
			body.set_idle()

func exit_state(old_state):
	match old_state:
		State.ATTACK:
			current_attack_cooldown = attack_cooldown_time
			current_weapon.finish_attack()
			set_current_weapon()
		State.PREP:
			current_attack_cooldown = attack_cooldown_time
			if prep_tween != null and prep_tween.is_valid():
				prep_tween.kill()
			body_container.scale.y = 1
		State.DASH:
			velocity = Vector2.ZERO
			current_dash_cooldown = dash_cooldown_time
			hitbox_col.disabled = false

func set_current_weapon():
	var weapon_index = randi_range(0, possible_weapons.size() - 1)
	current_weapon = possible_weapons[weapon_index]

func take_damage(damage: int, attacker_position: Vector2):
	if state == State.DAMAGE or state == State.DASH:
		return

	if current_damage_cooldown > 0.0:
		return
	
	SoundController.play_sfx(damage_sfx, randf_range(0.9, 1.1), randf_range(0.6, 0.8))
	health -= damage
	current_damage_cooldown = damage_cooldown_time
	health_boss.update_health(health)
	current_state_time = dash_time
	if health <= 0:
			WhiteFade.fade_in()
			dead.emit()
			queue_free()
	
	last_input = (global_position - Global.player.global_position).normalized()
	velocity = last_input * recoil_impulse
	if state != State.PREP:
		state = State.DAMAGE
	
	damage_particle.look_at(damage_particle.global_position + last_input)
	damage_particle.emitting = true
	damage_particle.restart()

func update_animation():
	var dir = Global.player.global_position - global_position
	
	if state == State.ATTACK:
		dir = last_input
	
	look_down.hide()
	look_up.hide()
	
	body_container.scale.x = 1 if dir.x >= 0 else -1
	
	var animation_prefix = "idle"
	var animation_suffix = "_down"
	
	if(dir.y >= 0):
		look_down.show()
	else:
		look_up.show()
		animation_suffix = "_up"
		
	match state:
		State.WALK:
			if velocity.length() > 0.1:
				animation_prefix = "run"
			else:
				animation_prefix = "idle"
		State.DASH:
			animation_prefix = "dash"
		State.ATTACK:
			animation_prefix = "attack"
	
	var new_animation = animation_prefix + animation_suffix
	if animation.current_animation.get_basename() != new_animation:
		animation.play(animation_prefix + animation_suffix)
	
	
	
