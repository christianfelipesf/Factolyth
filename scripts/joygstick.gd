extends Control

@onready var knob: Sprite2D = $TouchScreenButton/Sprite2D

var max_distance := 50.0
var joystick_vector := Vector2.ZERO
var is_dragging := false
var _centro := Vector2.ZERO

func _ready() -> void:
	_centro = knob.global_position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and event.position.distance_to(_centro) <= max_distance:
				is_dragging = true
				get_viewport().set_input_as_handled()
			elif not event.pressed:
				_resetar()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		_arrastar(event.position)
		get_viewport().set_input_as_handled()

	elif event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(_centro) <= max_distance:
			is_dragging = true
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			_resetar()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag and is_dragging:
		_arrastar(event.position)
		get_viewport().set_input_as_handled()

func esta_arrastando() -> bool:
	return is_dragging

func _arrastar(pos: Vector2) -> void:
	var desloc := pos - _centro
	var limitado := desloc.limit_length(max_distance)
	knob.global_position = _centro + limitado
	joystick_vector = limitado / max_distance

func _resetar() -> void:
	is_dragging = false
	joystick_vector = Vector2.ZERO
	knob.global_position = _centro

func get_velocity() -> Vector2:
	return joystick_vector
