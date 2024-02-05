extends Node2D

@export var enemies: Array[EnemyData]

@export var budget_per_level: int = 10
@export var budget_per_wave: int = 3


#func _ready():
	#for i in range(1,30):
		#for j in range(1,4):
			#var wave = generate_wave(i, j)
			#
			#var value = "Stage: " + str(i) + " Wave: " + str(j) + " | "
			#for enemy in wave:
				#value += enemy.name + " | "
			#print(value)
		#print("------")


func generate_wave(current_stage, current_wave) -> Array[EnemyData]:
	
	# The budget grows indefinitely
	var total_budget = (current_stage * budget_per_level) + (current_wave * budget_per_wave)
	
	# The enemy spawn don't
	if current_stage > 9:
		current_stage = 9
	
	var enemy_pool = []
	var n_attempts = 0
	var cheapest_enemy_cost = 100000
	
	while(!pool_is_valid(enemy_pool) and n_attempts < 3):
		enemy_pool = []
		for enemy in enemies:
			if include_enemy_in_pool(current_stage, enemy):
				enemy_pool.append(enemy)
				if enemy.cost < cheapest_enemy_cost:
					cheapest_enemy_cost = enemy.cost
		n_attempts += 1
	
	if n_attempts ==3:
		push_warning("MOving forward on stage ", current_stage, " with invalid pool :(")
	
	# Filter out all enemies who cost more than 30% of the current budget
	# This is so we guarante at least 4 enemies per wave
	enemy_pool = enemy_pool.filter(func(enemy: EnemyData): return enemy.cost <= (total_budget * 0.2))
	
	# Starts process to create wave
	var wave: Array[EnemyData] = []
	n_attempts = 0
	var last_index = -1
	
	# Will wrap up the wave creation if it fails to get more enemies, or if has no more budget left
	# for the enemies in the pool
	while(n_attempts < 3 and total_budget > cheapest_enemy_cost):
		# First picks a random enemy in the pool, that is different from the last one 
		# if the pool has more than on element
		var index = randi_range(0, enemy_pool.size() - 1)
		
		if enemy_pool.size() > 1:
			while(index == last_index):
				index = randi_range(0, enemy_pool.size() - 1)
		
		var enemy: EnemyData = enemy_pool[index]
		
		# If it can't pay for this enemy, increase attempts and remove it from the options
		if enemy.cost > total_budget:
			enemy_pool.remove_at(index)
			n_attempts += 1
			continue
		
		# Otherwise adds the enemy to the wave, subtracts the budget, and reset attempts
		wave.append(enemy)
		total_budget -= enemy.cost
		n_attempts = 0
		last_index = index
	
	if wave.size() == 0:
		push_warning("Created empty wave :(")
	
	return wave
	
		

func include_enemy_in_pool(current_stage: int, enemy: EnemyData) -> bool:
	# We first get how far we are from the preffered stage
	var stage_distance = (abs(current_stage - enemy.preffered_stage))
	
	# If we are too far from the preffered stage, early return
	if stage_distance > enemy.stage_decay:
		return false
		
	# Get a value from 0.0 to 1.0 depending on how far we are from the preffered
	# E.g.: if distance is 0 (we are on the preffered stage) the chances is 1.0
	# if we are at the edge (distance is stage decay value), chances are 1.0/stage decay
	var chances = inverse_lerp(enemy.stage_decay, 0, stage_distance)
	
	# If there are no chances of being in the preffered zone, return early
	if chances <= 0.0:
		return false
		
	# If the chances are max, also return early (with true)
	if chances >= 1.0:
		return true
		
	# Otherwise, return randomly if this enemy should be in the pool, based on the chances
	var dice = randf_range(0.0, 1.0)
	
	return chances > dice
	
# We should always have at least two enemies to battle with
func pool_is_valid(pool) -> bool:
	return pool.size() >= 2
		
