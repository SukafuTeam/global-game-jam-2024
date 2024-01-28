extends TextureRect

@export var keyboard_texture: Texture
@export var gamepad_texture: Texture

func _ready():
	InputDetector.input_changed.connect(func(is_gamepad):
		texture = gamepad_texture if is_gamepad else keyboard_texture
	)

