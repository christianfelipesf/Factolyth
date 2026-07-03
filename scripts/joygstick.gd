extends Control

## Distância máxima que o knob pode se afastar do centro.
## Também é o raio onde o clique inicia o arrasto.
@export var raio_maximo := 50.0

## Área extra ao redor do raio_maximo que BLOQUEIA a colocação de blocos,
## mas NÃO ativa o arrasto do joystick. Funciona como zona de segurança.
@export var margem := 50.0

## Distância a partir do centro onde o movimento é ignorado (joystick_vector = zero).
@export var zona_morta := 10.0

@onready var knob: Sprite2D = $TouchScreenButton/Sprite2D

var joystick_vector := Vector2.ZERO
var is_dragging := false
var _centro := Vector2.ZERO

func _ready() -> void:
	_centro = knob.global_position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Arrasto só ativa DENTRO do raio_maximo (ignora a margem)
			if event.pressed and event.position.distance_to(_centro) <= raio_maximo:
				is_dragging = true
				_arrastar(event.position)
				get_viewport().set_input_as_handled()
			elif not event.pressed and is_dragging:
				_resetar()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		_arrastar(event.position)
		get_viewport().set_input_as_handled()

	elif event is InputEventScreenTouch:
		# Arrasto só ativa DENTRO do raio_maximo (ignora a margem)
		if event.pressed and event.position.distance_to(_centro) <= raio_maximo:
			is_dragging = true
			_arrastar(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and is_dragging:
			_resetar()
			get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag and is_dragging:
		_arrastar(event.position)
		get_viewport().set_input_as_handled()

func esta_arrastando() -> bool:
	return is_dragging

func _arrastar(pos: Vector2) -> void:
	var desloc := pos - _centro
	var limitado := desloc.limit_length(raio_maximo)
	knob.global_position = _centro + limitado

	# Zona morta: ignora deslocamentos pequenos no centro
	var distancia := desloc.length()
	if distancia <= zona_morta:
		joystick_vector = Vector2.ZERO
	else:
		var intensidade := clampf(
			(distancia - zona_morta) / (raio_maximo - zona_morta),
			0.0, 1.0
		)
		var direcao := limitado.normalized() if limitado.length() > 0.0 else Vector2.ZERO
		joystick_vector = direcao * intensidade

func _resetar() -> void:
	is_dragging = false
	joystick_vector = Vector2.ZERO
	knob.global_position = _centro

func get_velocity() -> Vector2:
	return joystick_vector

## Verifica se uma posição na tela está dentro da área do joystick
## (incluindo a margem de segurança). Útil para evitar colocar blocos em cima da UI.
func is_na_area_de_ui(pos_tela: Vector2) -> bool:
	return pos_tela.distance_to(_centro) <= raio_maximo + margem


func _on_teste_pressed() -> void:
	pass # Replace with function body.
