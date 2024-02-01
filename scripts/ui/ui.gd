extends CanvasLayer
class_name Ui

@onready var progress: TextureProgressBar = $Container/RaziMeio/BarraWave/TextureProgressBar
@onready var wave_progress: Control = $Container/RaziMeio

@onready var weapon_icon: TextureRect = $Container/RaizItem/WeaponContainer/WeaponIcon
@onready var secondary_icon: TextureRect = $Container/RaizItem/SecundaryContainer/SecondaryIcon
@onready var secondary_progress: TextureProgressBar = $Container/RaizItem/SecundaryContainer/SecondaryIcon/SecondaryProgress
var secondary_flash: float

@export var hearts: Array[TextureRect] = []
@export var manas: Array[TextureRect] = []

var original_heart_offsets = []

@onready var stage_counter: Label = $"Container/StageCounterContainer/NumberContainer/Stage Counter2"

var time: float

func _ready():
	
	stage_counter.text = str(Global.current_stage)
	
	weapon_icon.texture = Global.weapons[Global.weapon_index].icon
	if Global.secondary_index == -1:
		secondary_icon.texture = null
		secondary_progress.texture_progress = null
	else:
		var text = Global.secondaries[Global.secondary_index].icon
		secondary_icon.texture = text
		secondary_progress.texture_progress = text
	
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
		var text = data.icon
		secondary_icon.texture = text
		secondary_progress.texture_progress = text
		var tween = create_tween()
		var oscale = secondary_icon.scale
		tween.tween_property(secondary_icon, "scale", oscale * 1.2, 0.2)
		tween.tween_property(secondary_icon, "scale", oscale, 0.2)
	)
	
	for i in 5:
		original_heart_offsets.append(hearts[i].position.y)
		
	secondary_progress.value = 100
	
func _process(delta):
	time +=delta
	for i in 5:
		hearts[i].position.y = original_heart_offsets[i] + sin((time + i) * 10) * 2
	
	for i in 5:
		manas[i].rotation_degrees = sin((time + (i*5)) * 6) * 10
		
	secondary_progress.material.set_shader_parameter("flash_intensity", secondary_flash)
	
func update_progress(value):
	if value > 95:
		value = 100
	progress.value = value

func update_seconday(value):
	var prev_value = secondary_progress.value
	secondary_progress.value = int(value * 100)
	
	if prev_value < 100 and int(value * 100) == 100:
		var tween = create_tween()
		tween.tween_property(self, "secondary_flash", 1.0, 0.1)
		tween.tween_property(self, "secondary_flash", 0.0, 0.5)
