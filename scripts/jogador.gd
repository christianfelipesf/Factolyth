extends CharacterBody2D

const MAX_SPEED = 400.0
const ACCELERATION = 1200.0
const FRICTION = 600.0
const ROTATION_SPEED = 10.0

# --- CONFIGURAÇÕES DA CÂMERA ---
@export var MIN_ZOOM := 0.5       
@export var MAX_ZOOM := 1.5       
@export var ZOOM_SPEED := 5.0     
@export var ZOOM_STEP := 0.05     

# --- 🌟 ITENS CONSTRUÍVEIS (carregados automaticamente de res://scenes/posicionaveis/) ---
var _itens_construcao: Array[ItemConstrucao] = []
var _indice_item_atual: int = -1

signal item_selecionado(indice: int)

@onready var target_zoom_value: float = (MIN_ZOOM + MAX_ZOOM) / 2.0
@onready var camera: Camera2D = $Camera2D 
@onready var marker: Marker2D = $Marker2D

var _pontos_toque: Dictionary = {}
var _pinça_iniciada: bool = false
var _distancia_pinça_inicial: float = 0.0
var _zoom_inicial_pinça: float = 0.0

func _ready() -> void:
	carregar_itens_construcao()
	if not _itens_construcao.is_empty():
		selecionar_item_por_indice(0)

func carregar_itens_construcao() -> void:
	_adicionar_item_com_cena("Broca", _BROCA)
	_adicionar_item_com_cena("Esteira", _ESTEIRA)
	_adicionar_item_com_cena("Nucleo", _NUCLEO)
	_adicionar_item_com_cena("Canhao", _CANHAO)
	if _itens_construcao.is_empty():
		push_error("Nenhum item construível encontrado")

const _BROCA = preload("res://scenes/posicionaveis/broca.tscn")
const _ESTEIRA = preload("res://scenes/posicionaveis/esteira.tscn")
const _NUCLEO = preload("res://scenes/posicionaveis/nucleo.tscn")
const _CANHAO = preload("res://scenes/posicionaveis/simplecanon.tscn")

func _adicionar_item_com_cena(nome: String, cena: PackedScene) -> void:
	var item = ItemConstrucao.new()
	item.nome = nome
	item.cena_objeto = cena
	item.compensar_rotacao_90 = false
	item.tamanho_grid = _extrair_tamanho_grid(cena)
	_itens_construcao.append(item)

@onready var joystick: Control = get_tree().root.find_child("Joystick", true, false)

func _physics_process(delta: float) -> void:
	# 1. Movimento e Direção da Nave
	var input_direction := Vector2.ZERO
	
	# Primeiro tenta ler o teclado com base no seu Input Map (WASD)
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	
	# Se nenhuma tecla for apertada e o joystick existir, lê o Joystick virtual
	if input_direction == Vector2.ZERO and joystick:
		input_direction = joystick.get_velocity()
		
	input_direction = input_direction.normalized()
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move_and_slide()

	if velocity.length() > 10.0:
		var target_angle = velocity.angle()
		rotation = rotate_toward(rotation, target_angle, ROTATION_SPEED * delta)

	# 2. Suavização do Zoom (Sua lógica original mantida)
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
	# [Lógica do Zoom com scroll]
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom_value += ZOOM_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom_value -= ZOOM_STEP
		target_zoom_value = clamp(target_zoom_value, MIN_ZOOM, MAX_ZOOM)

	# [🌟 CICLO DE ITENS COM E / TECLAS 1-4]
	if event.is_action_pressed("interact"):
		if _itens_construcao.is_empty():
			return
		var novo = (_indice_item_atual + 1) % _itens_construcao.size()
		selecionar_item_por_indice(novo)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: selecionar_item_por_indice(0)
			KEY_2: selecionar_item_por_indice(1)
			KEY_3: selecionar_item_por_indice(2)
			KEY_4: selecionar_item_por_indice(3)

func is_pinçando() -> bool:
	return _pinça_iniciada


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

func _extrair_tamanho_grid(cena: PackedScene) -> Vector2i:
	var inst = cena.instantiate()
	if inst == null:
		return Vector2i(1, 1)
	var val = inst.get("TAMANHO_GRID")
	inst.free()
	return val if val != null else Vector2i(1, 1)

func get_save_data() -> Dictionary:
	return {
		posicao = [global_position.x, global_position.y],
		rotacao = rotation,
		zoom = target_zoom_value,
		item_atual = _indice_item_atual
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
	camera.position_smoothing_enabled = true
