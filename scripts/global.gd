extends Node

signal weapon_changed(weapon: WeaponData)
signal secondary_changed(secondary: SecondaryData)

signal enemy_killed(new_amount)
signal wave_cleared()
signal health_changed(new_value)
signal mana_changed(new_value)

var player: Node2D

var health: int:
	set(value):
		health_changed.emit(value)
		health = value
	get:
		return health

var mana: int:
	set(value):
		mana_changed.emit(value)
		mana = value
	get:
		return mana

var damage: int
var speed: int

var weapon_index: int:
	set(value):
		weapon_changed.emit(weapons[value])
		weapon_index = value
	get:
		return weapon_index
		
var secondary_index: int:
	set(value):
		secondary_changed.emit(secondaries[value])
		secondary_index = value
	get:
		return secondary_index

var weapons: Array[WeaponData] = [
	preload("res://data/weapons/sword_data.tres"),
	preload("res://data/weapons/axe_data.tres"),
	preload("res://data/weapons/spear_data.tres"),
	preload("res://data/weapons/drill_data.tres")
]

var secondaries: Array[SecondaryData] = [
	preload("res://data/secondaries/lure_item.tres"),
	preload("res://data/secondaries/shield_secondary.tres"),
	preload("res://data/secondaries/invincibility_secondary.tres"),
	preload("res://data/secondaries/acid_secondary.tres")
]

var player_damage: int:
	get:
		return weapons[weapon_index].damage + damage

var death_enemy_particle: PackedScene = preload("res://entities/global/enemy_death.tscn")

var current_stage: int
var enemies_alive: int

func _ready():
	process_priority = -1000
	reset_stats()
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_stats():
	health = 5
	mana = 5
	damage = 0
	speed = 0
	weapon_index = 0
	secondary_index = -1
	current_stage = 1
	
func spawn_enemy_death(position: Vector2, new_color: Color):
	var particle = death_enemy_particle.instantiate() as EnemyDeath
	add_child(particle)
	particle.global_position = position
	particle.setup(new_color)
	
func add_enemy():
	enemies_alive += 1

func remove_enemy():
	enemies_alive -= 1
	enemy_killed.emit(enemies_alive)
	if enemies_alive == 0:
		wave_cleared.emit()
		
func equip_weapon(index):
	if player.weapon != null:
		player.weapon.queue_free()
		player.weapon = null
	var weapon_data = weapons[index]
	var instance = weapon_data.entity.instantiate() as Weapon
	player.add_child(instance)
	instance.position = weapon_data.spawn_offset
	player.weapon = instance
	weapon_index = index

func equip_secondary(index):
	if index  == -1:
		return
	
	if player.secondary != null:
		player.secondary.queue_free()
		player.secondary = null
	var secondary_data = secondaries[index]
	var instance = secondary_data.scene.instantiate() as SecondaryItem
	player.add_child(instance)
	player.secondary = instance
	secondary_index = index
	
func get_random_weapon():
	var selected = weapon_index
	while selected == weapon_index:
		selected = randi_range(0, weapons.size()-1)
	
	return selected

func get_random_secondary():
	var selected = secondary_index
	while selected == secondary_index:
		selected = randi_range(0, secondaries.size()-1)
	
	return selected
