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

@onready var target_zoom_value: float = (MIN_ZOOM + MAX_ZOOM) / 2.0
@onready var camera: Camera2D = $Camera2D 
@onready var marker: Marker2D = $Marker2D

func _ready() -> void:
	carregar_itens_construcao()

func carregar_itens_construcao() -> void:
	var dir = DirAccess.open("res://scenes/posicionaveis/")
	if dir != null:
		_carregar_itens_do_dir(dir)
	else:
		_carregar_itens_do_manifesto()

	if _itens_construcao.is_empty():
		push_error("Nenhum item construível encontrado em res://scenes/posicionaveis/")

func _carregar_itens_do_dir(dir: DirAccess) -> void:
	dir.list_dir_begin()
	var nome_arquivo = dir.get_next()
	while nome_arquivo != "":
		if nome_arquivo.ends_with(".tscn") and not nome_arquivo.begins_with("."):
			_adicionar_item("res://scenes/posicionaveis/" + nome_arquivo, nome_arquivo.replace(".tscn", "").capitalize())
		nome_arquivo = dir.get_next()
	dir.list_dir_end()

func _carregar_itens_do_manifesto() -> void:
	var caminhos := PackedStringArray()
	caminhos.append("res://scenes/posicionaveis/broca.tscn")
	caminhos.append("res://scenes/posicionaveis/esteira.tscn")
	caminhos.append("res://scenes/posicionaveis/nucleo.tscn")
	caminhos.append("res://scenes/posicionaveis/simplecanon.tscn")
	for caminho in caminhos:
		var nome_arquivo = caminho.get_file().replace(".tscn", "").capitalize()
		_adicionar_item(caminho, nome_arquivo)

func _adicionar_item(caminho: String, nome: String) -> void:
	var cena = load(caminho) as PackedScene
	if cena == null:
		return
	var item = ItemConstrucao.new()
	item.nome = nome
	item.cena_objeto = cena
	item.compensar_rotacao_90 = false
	item.tamanho_grid = _extrair_tamanho_grid(cena)
	_itens_construcao.append(item)

func _physics_process(delta: float) -> void:
	# 1. Movimento e Direção da Nave
	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move_and_slide()

	if velocity.length() > 10.0:
		var target_angle = velocity.angle()
		rotation = rotate_toward(rotation, target_angle, ROTATION_SPEED * delta)

	# 2. Suavização do Zoom
	var target_zoom = Vector2(target_zoom_value, target_zoom_value)
	camera.zoom = camera.zoom.lerp(target_zoom, ZOOM_SPEED * delta)

func _unhandled_input(event: InputEvent) -> void:
	# [Lógica do Zoom]
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom_value += ZOOM_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom_value -= ZOOM_STEP
		target_zoom_value = clamp(target_zoom_value, MIN_ZOOM, MAX_ZOOM)

	# [🌟 CICLO DE ITENS COM E]
	if event.is_action_pressed("interact"):
		if _itens_construcao.is_empty():
			return
		_indice_item_atual = (_indice_item_atual + 1) % _itens_construcao.size()
		var item = _itens_construcao[_indice_item_atual]
		marker.equipar_item(item)
		print("🔧 Item selecionado: ", item.nome)

func _extrair_tamanho_grid(cena: PackedScene) -> Vector2i:
	var inst = cena.instantiate()
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
	if dados.has("posicao"):
		var p: Array = dados.posicao
		global_position = Vector2(p[0], p[1])
	if dados.has("rotacao"):
		rotation = dados.rotacao
	if dados.has("zoom"):
		target_zoom_value = dados.zoom
	if dados.has("item_atual"):
		_indice_item_atual = dados.item_atual
		if _indice_item_atual >= 0 and _indice_item_atual < _itens_construcao.size():
			marker.equipar_item(_itens_construcao[_indice_item_atual])
