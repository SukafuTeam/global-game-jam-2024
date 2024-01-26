extends CanvasLayer
class_name LogoScene

@onready var logo_image: TextureRect = $Background/LogoImage

@export var logo_sound: AudioStream

func _ready():
	logo_image.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func(): SoundController.play_sfx(logo_sound))
	tween.tween_property(logo_image, "modulate:a", 1, 2)
	tween.tween_interval(2.5)
	tween.tween_property(logo_image, "modulate:a", 0, 1)
	tween.tween_callback(func(): Transition.change_scene("res://scenes/menu_scene.tscn"))
