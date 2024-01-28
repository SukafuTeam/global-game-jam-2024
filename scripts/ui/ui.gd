extends CanvasLayer
class_name Ui

@onready var wave_counter: Label = $Container/WaveCounter
@onready var progress: TextureProgressBar = $Container/RaziMeio/BarraWave/TextureProgressBar
@onready var wave_progress: Control = $Container/RaziMeio

@export var hearts: Array[TextureRect] = []
@export var manas: Array[TextureRect] = []

func _ready():
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
		

func update_stage_wave(stage, wave):
	wave_counter.text = "Stage: " + str(stage) + "\n Wave: " + str(wave)
	
func update_progress(value):
	if value > 95:
		value = 100
	progress.value = value

