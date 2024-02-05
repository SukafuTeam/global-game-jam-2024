extends CanvasLayer
class_name PauseController


func _ready():
	hide()

func _process(_delta):
	if Input.is_action_just_pressed("pause") and Global.health > 0:
		pause()

func pause():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused
	
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Master"), 0, get_tree().paused)
