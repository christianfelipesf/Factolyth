extends CharacterBody2D

const MAX_SPEED = 400.0
const ACCELERATION = 1200.0
const FRICTION = 600.0
const ROTATION_SPEED = 10.0

@export var MIN_ZOOM := 0.5
@export var MAX_ZOOM := 1.5
@export var ZOOM_SPEED := 5.0
@export var ZOOM_STEP := 0.05

var _itens_construcao: Array[ItemConstrucao] = []
var _indice_item_atual: int = -1

signal item_selecionado(indice: int)
signal itens_construcao_atualizados()

@onready var target_zoom_value: float = (MIN_ZOOM + MAX_ZOOM) / 2.0
@onready var camera: Camera2D = $Camera2D
@onready var marker: Marker2D = $Marker2D

var _pontos_toque: Dictionary = {}
var _pinça_iniciada: bool = false
var _distancia_pinça_inicial: float = 0.0
var _zoom_inicial_pinça: float = 0.0
var controles_travados := false
var inventario: Dictionary = {}

signal inventario_atualizado(inv: Dictionary)

var _broca_module: JogadorBrocaModule
var _inv_module: JogadorInventarioModule


func _ready() -> void:
	_broca_module = JogadorBrocaModule.new()
	_broca_module.setup(self)
	_inv_module = JogadorInventarioModule.new()
	_inv_module.setup(self)

	_inv_module.carregar_itens_construcao()
	if not _itens_construcao.is_empty():
		selecionar_item_por_indice(0)


@onready var joystick: Control = get_tree().root.find_child("Joystick", true, false)


func _physics_process(delta: float) -> void:
	if controles_travados:
		return

	_broca_module.process(delta)

	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")

	if input_direction == Vector2.ZERO:
		var stick := Vector2(
			Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		)
		if stick.length() > 0.2:
			input_direction = stick

	if input_direction == Vector2.ZERO:
		var stick := Vector2(
			Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		)
		if stick.length() > 0.2:
			input_direction = stick
		elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
			input_direction.x = -1
		elif Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
			input_direction.x = 1
		if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
			input_direction.y = -1
		if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
			input_direction.y = 1

	if input_direction == Vector2.ZERO and joystick:
		input_direction = joystick.get_velocity()

	input_direction = input_direction.normalized()

	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()

	if velocity.length() > 10.0:
		var target_angle = velocity.angle() + PI / 2
		rotation = rotate_toward(rotation, target_angle, ROTATION_SPEED * delta)

	var target_zoom = Vector2(target_zoom_value, target_zoom_value)
	camera.zoom = camera.zoom.lerp(target_zoom, ZOOM_SPEED * delta)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pontos_toque[event.index] = event.position
		else:
			_pontos_toque.erase(event.index)
		_pinça_iniciada = false

	if event is InputEventScreenDrag:
		_pontos_toque[event.index] = event.position

	if _pontos_toque.size() >= 2:
		var keys = _pontos_toque.keys()
		var pos1: Vector2 = _pontos_toque[keys[0]]
		var pos2: Vector2 = _pontos_toque[keys[1]]
		var dist_atual := pos1.distance_to(pos2)

		if not _pinça_iniciada:
			_pinça_iniciada = true
			_distancia_pinça_inicial = dist_atual
			_zoom_inicial_pinça = target_zoom_value
		else:
			var fator := dist_atual / _distancia_pinça_inicial
			target_zoom_value = clamp(_zoom_inicial_pinça * fator, MIN_ZOOM, MAX_ZOOM)
	else:
		_pinça_iniciada = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom_value += ZOOM_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom_value -= ZOOM_STEP
		target_zoom_value = clamp(target_zoom_value, MIN_ZOOM, MAX_ZOOM)

	var hud = get_node_or_null("/root/Mundo/Playerui/UI/CraftingHUD")
	if event.is_action_pressed("craft"):
		if hud:
			hud.toggle()
			_input_handled()
			return
	if hud != null and hud.visible and event.is_action_pressed("ui_cancel"):
		hud.toggle()
		_input_handled()
		return

	if event.is_action_pressed("alterar"):
		if _itens_construcao.is_empty():
			return
		var novo = (_indice_item_atual + 1) % _itens_construcao.size()
		selecionar_item_por_indice(novo)
		_input_handled()
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			if _itens_construcao.is_empty():
				return
			var novo = (_indice_item_atual + 1) % _itens_construcao.size()
			selecionar_item_por_indice(novo)
			_input_handled()
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			if _itens_construcao.is_empty():
				return
			var novo = (_indice_item_atual - 1 + _itens_construcao.size()) % _itens_construcao.size()
			selecionar_item_por_indice(novo)
			_input_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: selecionar_item_por_indice(0)
			KEY_2: selecionar_item_por_indice(1)
			KEY_3: selecionar_item_por_indice(2)
			KEY_4: selecionar_item_por_indice(3)
			KEY_5: selecionar_item_por_indice(4)
			KEY_6: selecionar_item_por_indice(5)
			KEY_7: selecionar_item_por_indice(6)


func get_itens_construcao() -> Array:
	return _itens_construcao


func get_indice_item_atual() -> int:
	return _indice_item_atual


func selecionar_item_por_indice(indice: int) -> void:
	if indice < 0 or indice >= _itens_construcao.size():
		return
	_indice_item_atual = indice
	marker.equipar_item(_itens_construcao[_indice_item_atual])
	item_selecionado.emit(indice)


func usar_broca_manual(pos: Vector2) -> void:
	_broca_module.usar_broca_manual(pos)


func esta_em_cooldown_broca() -> bool:
	return _broca_module.esta_em_cooldown_broca()


func adicionar_item(tipo_id: String, quantidade: int = 1) -> void:
	_inv_module.adicionar_item(tipo_id, quantidade)


func adicionar_item_construcao(item: ItemConstrucao) -> void:
	_inv_module.adicionar_item_construcao(item)


func remover_item_construcao(nome: String) -> void:
	_inv_module.remover_item_construcao(nome)


func get_save_data() -> Dictionary:
	return {
		posicao = [global_position.x, global_position.y],
		rotacao = rotation,
		zoom = target_zoom_value,
		item_atual = _indice_item_atual,
		inventario = inventario.duplicate()
	}


func set_save_data(dados: Dictionary) -> void:
	velocity = Vector2.ZERO
	camera.position_smoothing_enabled = false
	if dados.has("posicao"):
		var p: Array = dados.posicao
		global_position = Vector2(p[0], p[1])
	if dados.has("rotacao"):
		rotation = dados.rotacao
	if dados.has("zoom"):
		target_zoom_value = dados.zoom
	if dados.has("item_atual"):
		selecionar_item_por_indice(dados.item_atual)
	if dados.has("inventario"):
		inventario = {}
		for key in dados.inventario:
			inventario[key] = int(dados.inventario[key])
		inventario_atualizado.emit(inventario)
	camera.position_smoothing_enabled = true


func is_pinçando() -> bool:
	return _pinça_iniciada


func _input_handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()
