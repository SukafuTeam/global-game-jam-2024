extends Node

signal input_changed(is_gamepad: bool)

func _input(event):
	var move_input = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0,JOY_AXIS_LEFT_Y))
	if (event is InputEventKey) or (event is InputEventMouse):
		input_changed.emit(false)
	elif(event is InputEventJoypadButton) or move_input.length() > 0.1:
		input_changed.emit(true)

