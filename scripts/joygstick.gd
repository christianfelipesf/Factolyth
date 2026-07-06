extends Control

@export var raio_maximo := 50.0
@export var margem := 50.0
@export var zona_morta := 10.0

@onready var knob: TextureButton = $TextureButton

var joystick_vector := Vector2.ZERO
var is_dragging := false
var _centro := Vector2.ZERO
var _pos_base := Vector2.ZERO
var _tamanho_controle := Vector2.ZERO

func _ready() -> void:
	_pos_base = knob.position
	_tamanho_controle = knob.size if knob.size != Vector2.ZERO else knob.custom_minimum_size
	_centro = _pos_base + _tamanho_controle * knob.scale * 0.5

func _tem_hud_craft_aberta() -> bool:
	var hud = get_node_or_null("/root/Mundo/Playerui/UI/CraftingHUD")
	return hud != null and hud.visible


func _input(event: InputEvent) -> void:
	if _tem_hud_craft_aberta():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
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
	knob.position = _pos_base + limitado

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
	knob.position = _pos_base

func get_velocity() -> Vector2:
	return joystick_vector

func is_na_area_de_ui(pos_tela: Vector2) -> bool:
	return pos_tela.distance_to(_centro) <= raio_maximo + margem
