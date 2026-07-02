extends Control

@onready var knob: Sprite2D = $TouchScreenButton/Sprite2D

var max_distance := 50.0
var joystick_vector := Vector2.ZERO
var is_dragging := false
var _centro := Vector2.ZERO

func _ready() -> void:
	_centro = size / 2.0
	knob.position = _centro

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _dentro_do_joystick(event.position):
				is_dragging = true
			elif not event.pressed:
				_resetar()

	elif event is InputEventMouseMotion and is_dragging:
		_arrastar(event.position)

	elif event is InputEventScreenTouch:
		if event.pressed and _dentro_do_joystick(event.position):
			is_dragging = true
		elif not event.pressed:
			_resetar()

	elif event is InputEventScreenDrag and is_dragging:
		_arrastar(event.position)

func _dentro_do_joystick(pos: Vector2) -> bool:
	return (pos - global_position - _centro).length() <= max_distance

func _arrastar(pos: Vector2) -> void:
	var desloc := pos - global_position - _centro
	var limitado := desloc.limit_length(max_distance)
	knob.position = _centro + limitado
	joystick_vector = limitado / max_distance

func _resetar() -> void:
	is_dragging = false
	joystick_vector = Vector2.ZERO
	knob.position = _centro

func get_velocity() -> Vector2:
	return joystick_vector
