extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

func _ready():
	rect.modulate.a = 0.0


func fade_in():
	rect.modulate.a = 1.0

func fade_out(time:float = 2.0):
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, time)
