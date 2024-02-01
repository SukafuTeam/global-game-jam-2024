extends CanvasLayer

signal fade_in_finished
signal fade_out_finished

@onready var circle: Sprite2D = $Circle
@onready var fade: ColorRect = $Circle/Fade
var transitioning: bool

func _ready():
	circle.scale = Vector2.ONE * 5
	fade.modulate.a = 0.0
	circle.global_position = circle.get_viewport_rect().size / 2

func transtition(origin_position: Vector2, target_position: Vector2, new_scene: String):
	if transitioning:
		return
	
	transitioning = true
	var tween = create_tween()
	circle.global_position = origin_position
	circle.scale = Vector2.ONE * 5
	tween.tween_property(circle, "scale", Vector2.ONE * 0.4, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_interval(0.5)
	tween.tween_property(circle, "scale", Vector2.ONE * 0.02, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(fade, "modulate:a", 1.0, 0.3)

	await tween.finished

	fade_in_finished.emit()
	
	get_tree().change_scene_to_file(new_scene)
	circle.global_position = target_position
	
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.1)
	tween.tween_property(circle, "scale", Vector2.ONE * 0.4, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_interval(0.5)
	tween.tween_property(circle, "scale", Vector2.ONE * 5, 0.5)

	await tween.finished

	transitioning = false
	fade_out_finished.emit()
	
func reload_scene(origin_position: Vector2, target_position: Vector2):
	if transitioning:
		return
	
	transitioning = true
	var tween = create_tween()
	circle.scale = Vector2.ONE * 5
	circle.global_position = origin_position
	tween.tween_property(circle, "scale", Vector2.ONE * 0.4, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_interval(0.5)
	tween.tween_property(circle, "scale", Vector2.ONE * 0.02, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(fade, "modulate:a", 1.0, 0.3)

	await tween.finished

	fade_in_finished.emit()
	
	get_tree().reload_current_scene()
	circle.global_position = target_position
	
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.1)
	tween.tween_property(circle, "scale", Vector2.ONE * 0.4, 0.5).set_trans(Tween.TRANS_CIRC)
	tween.tween_interval(0.5)
	tween.tween_property(circle, "scale", Vector2.ONE * 5, 0.5)

	await tween.finished

	transitioning = false
	fade_out_finished.emit()
