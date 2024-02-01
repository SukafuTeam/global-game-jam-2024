extends Node2D

@onready var overlay: ColorRect = $CanvasLayer/Overlay
var transitioning: bool

func _ready():
	overlay.hide()

func change_scene(new_scene: String):
	_left_to_right_transition(func(): get_tree().change_scene_to_file(new_scene))

func reload_scene():
	_left_to_right_transition(func(): get_tree().reload_current_scene())

func _left_to_right_transition(callback: Callable):
	if transitioning:
		return
	
	transitioning = true
	overlay.show()
	var screen_size = get_viewport_rect().size.x
	overlay.position.x = -screen_size
	var tween = create_tween()
	tween.tween_property(overlay, "position:x", 0, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_callback(callback)
	tween.tween_property(overlay, "position:x", screen_size*2, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_callback(func():
		overlay.hide()
		transitioning = false
	)
