extends CanvasLayer
class_name Ui

@onready var wave_counter: Label = $Container/WaveCounter
@onready var progress: TextureProgressBar = $Container/RaziMeio/BarraWave/TextureProgressBar
@onready var wave_progress: Control = $Container/RaziMeio

@onready var weapon_icon: TextureRect = $Container/RaizItem/WeaponContainer/WeaponIcon
@onready var secondary_icon: TextureRect = $Container/RaizItem/SecundaryContainer/SecondaryIcon

@export var hearts: Array[TextureRect] = []
@export var manas: Array[TextureRect] = []

@onready var stage_counter: Label = $"Container/StageCounterContainer/NumberContainer/Stage Counter2"

func _ready():
	
	stage_counter.text = str(Global.current_stage)
	
	weapon_icon.texture = Global.weapons[Global.weapon_index].icon
	if Global.secondary_index == -1:
		secondary_icon.texture = null
	else:
		secondary_icon.texture = Global.secondaries[Global.secondary_index].icon
	
	for i in hearts.size():
		hearts[i].visible = Global.health > i

	for i in manas.size():
		manas[i].visible = Global.mana > i
	
	Global.health_changed.connect(func(value):
		for i in hearts.size():
			hearts[i].visible = value > i
	)
	
	Global.mana_changed.connect(func(value):
		for i in manas.size():
			manas[i].visible = value > i
	)
	
	Global.weapon_changed.connect(func(data):
		weapon_icon.texture = data.icon
		var tween = create_tween()
		var oscale = weapon_icon.scale
		tween.tween_property(weapon_icon, "scale", oscale * 1.2, 0.2)
		tween.tween_property(weapon_icon, "scale", oscale, 0.2)
	)
	
	Global.secondary_changed.connect(func(data):
		secondary_icon.texture = data.icon
		var tween = create_tween()
		var oscale = secondary_icon.scale
		tween.tween_property(secondary_icon, "scale", oscale * 1.2, 0.2)
		tween.tween_property(secondary_icon, "scale", oscale, 0.2)
	)
		

func update_stage_wave(stage, wave):
	wave_counter.text = "Stage: " + str(stage) + "\n Wave: " + str(wave)
	
func update_progress(value):
	if value > 95:
		value = 100
	progress.value = value

