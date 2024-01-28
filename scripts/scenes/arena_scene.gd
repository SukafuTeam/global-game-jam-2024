extends Node2D
class_name ArenaScene

var current_wave: int = 0

@onready var ui: Ui = $UI
@onready var camera: Camera2D = $Player/Camera2D
@onready var helicoper_spawn: Marker2D = $HelicopterSpawn
@onready var chest_spawn: Marker2D = $ChestSpawn

@onready var limpo: Node2D = $Scenario/Limpo

@export var enemy_spawn: PackedScene
@export var spawn_upper_limit: Vector2
@export var spawn_lower_limit: Vector2
@export var player_distance_threshold: float = 300

@export var chest_scene: PackedScene
@export var helicopter_scene: PackedScene

@export var game_bmg: AudioStream
@export var boss_bmg: AudioStream
@export var victory_bmg: AudioStream

@onready var slime_boss_location: Marker2D = $SlimeBossLocation
@export var slime_boss: PackedScene
@export var projectile_boss: PackedScene

@export var boss_particle: PackedScene

var total_enemies: int

func _ready():
	limpo.hide()
	ui.update_progress(0)
	SoundController.change_bmg("game", game_bmg)
	
	Global.enemy_killed.connect(func(enemies_alive):
		if total_enemies == 0:
			return
		
		var value = (current_wave - 1) * 33
		var value_per_enemy = 33.0 / total_enemies
		var enemies_killed = total_enemies - enemies_alive
		
		value += value_per_enemy * enemies_killed
		
		ui.update_progress(value)
	)
	
	Global.player.can_move = false
	print("Current Stage: " + str(Global.current_stage))
	current_wave = 1
	next_wave()
	
	ui.update_stage_wave(Global.current_stage, current_wave)

	Global.wave_cleared.connect(on_wave_clear)
	
	await get_tree().create_timer(1.0).timeout
	
	Global.player.can_move = true
	

func next_wave():
	print("Current Wave: " + str(current_wave))
	await get_tree().create_timer(1).timeout
	
	total_enemies = 0
	var wave = WaveSpawner.generate_wave(Global.current_stage, current_wave)
	total_enemies = wave.size()
	for wave_enemy in wave:
		var pos = get_spawn_position()
		var spawn = enemy_spawn.instantiate() as EnemySpawner
		add_child(spawn)
		spawn.global_position = pos
		var sce = wave_enemy.scene
		spawn.enemy = wave_enemy.scene
		spawn.setup()

func get_spawn_position() -> Vector2:
	var valid = false
	var spawn_pos = Vector2.ZERO
	
	while (!valid):
		spawn_pos = Vector2(
			randf_range(spawn_lower_limit.x, spawn_upper_limit.x),
			randf_range(spawn_lower_limit.y, spawn_upper_limit.y)
		)
		
		valid = (spawn_pos - Global.player.global_position).length() >= player_distance_threshold
		
	
	return spawn_pos
		
func on_wave_clear():
	current_wave += 1
	
	if current_wave > 2:
		return
	
	if current_wave == 2:
		ui.wave_progress.hide()
		if Global.current_stage % 3 != 0:
			end_stage()
			return
		
		call_deferred("add_boss")
		return
	
	ui.update_stage_wave(Global.current_stage, current_wave)
	next_wave()

func add_boss():
	Global.player.can_move = false
	Global.player.state = Global.player.State.IDLE
	Global.player.hide()
	var tween = create_tween()
	tween.tween_property(Global.player, "global_position", Vector2(895, 1121), 1.0)
	await tween.finished
	Global.player.show()
	
	tween = create_tween()
	tween.tween_property(get_viewport().get_camera_2d(), "global_position", slime_boss_location.global_position, 1.0)
	
	await tween.finished
	
	var par = boss_particle.instantiate() as EnemySpawner
	add_child(par)
	par.global_position = slime_boss_location.global_position
	par.enemy = null
	
	par.setup()
	
	await par.finished
	
	tween = create_tween()
	tween.tween_property(get_viewport().get_camera_2d(), "position", Vector2.ZERO, 0.5)
	Global.player.can_move = true
	
	SoundController.change_bmg("boss", boss_bmg)
	
	var scene = slime_boss
	
	if (Global.current_stage / 3) % 2 == 0:
		scene = projectile_boss
	
	var boss = scene.instantiate()
	add_child(boss)
	boss.global_position = slime_boss_location.global_position
	boss.dead.connect(func():
		await get_tree().create_timer(1.0).timeout
		limpo.show()
		Global.health = 5
		Global.mana = 5
		WhiteFade.fade_out()
		await get_tree().create_timer(2.0).timeout
		end_stage()
	)

func end_stage():
	SoundController.change_bmg("victory", victory_bmg)
	Global.current_stage += 1
	Global.player.can_move = false
	Global.player.state = Global.player.State.IDLE
	
	await get_tree().create_timer(0.5).timeout
	
	var tween = create_tween()
	var first_target = chest_spawn.global_position
	first_target.y -= 500
	tween.tween_property(
		camera,
		"global_position",
		first_target,
		2.0
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		var chest = chest_scene.instantiate()
		add_child(chest)
		chest.global_position = chest_spawn.global_position
	)
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		var heli = helicopter_scene.instantiate()
		add_child(heli)
		heli.global_position = helicoper_spawn.global_position
	)
	tween.tween_interval(2.0)
	tween.tween_property(camera, "position", Vector2(0,0), 0.5)
	tween.tween_callback(func(): Global.player.can_move = true)
