extends Weapon
class_name DrillWeapon

@onready var sprite_root: Node2D = $SpriteRoot

@onready var drill_tip: Sprite2D = $SpriteRoot/DrillBase/DrillTip
@onready var hurtbox: Area2D = $SpriteRoot/HurtBox

@onready var player: AudioStreamPlayer = $Sound

@export var cooldown_time: float = 0.3
var current_cooldown_time: float

@export var move_speed: float = 50.0

@export var slow_texture: Texture
@export var fast_texture: Texture
@export var swap_time_range:Vector2 = Vector2(0.2, 0.01)
var current_texture_time: float

@export var warm_time: float = 1.5
@export var overheat_time: float = 3.0
var current_drill_time: float

@export var heat_color: Color

var drilling: bool

func _ready():
	hurtbox.hide()
	sprite_root.hide()

func _process(delta):
	current_cooldown_time -= delta
	if !drilling:
		return
	
	if Input.is_action_just_released("attack"):
		drilling = false
		return
	
	current_drill_time += delta
	
	var warm_percent = inverse_lerp(0, warm_time, current_drill_time)
	warm_percent  = clamp(warm_percent, 0.0, 1.0)
	
	current_texture_time -= delta
	
	if current_texture_time <= 0:
		current_texture_time = inverse_lerp(swap_time_range.x, swap_time_range.y, warm_percent)
		drill_tip.flip_v = !drill_tip.flip_v
		drill_tip.texture = slow_texture if warm_percent < 0.9 else fast_texture
	
	hurtbox.visible = warm_percent >= 0.95
	
	if current_drill_time < warm_time:
		return
	
	var overheat_percent = inverse_lerp(warm_time, overheat_time, current_drill_time)
	
	if overheat_percent >= 0.99:
		drilling = false
	
	drill_tip.modulate = Color.WHITE.lerp(heat_color, overheat_percent)

func can_attack() -> bool:
	return current_cooldown_time <= 0.0
	
func attack(direction: Vector2):
	drilling = true
	current_drill_time = 0
	current_texture_time = swap_time_range.x
	drill_tip.texture = slow_texture
	sprite_root.look_at(sprite_root.global_position + direction)
	sprite_root.show()
	drill_tip.modulate = Color.WHITE
	
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()
	
func get_move_velocity() -> Vector2:
	var input = Input.get_vector("left", "right", "up", "down")
	return input * move_speed

func hit_something():
	pass

func get_areas():
	if current_drill_time < warm_time:
		return []
	
	for area in hurtbox.get_overlapping_areas():
		if area is Projectile:
			area.queue_free()
	
	return hurtbox.get_overlapping_areas()

func finished_attack():
	return !drilling

func finish_attack():
	hurtbox.hide()
	sprite_root.hide()
	current_cooldown_time = cooldown_time
	player.stop()
