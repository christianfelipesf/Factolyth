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

# --- CONFIGURAÇÕES DA BROCA ---
@export var CENA_BROCA: PackedScene 

@onready var target_zoom_value: float = (MIN_ZOOM + MAX_ZOOM) / 2.0
@onready var camera: Camera2D = $Camera2D 

# Pega a referência do seu nó filho chamado Marker
@onready var cursor_marker: Marker2D = $Marker2D

func _physics_process(delta: float) -> void:
	# 1. Movimento e Direção da Nave
	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
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

	# 3. Atualiza a posição do seu $Marker com base no mouse + limites da tela
	_atualizar_posicao_marker()

func _atualizar_posicao_marker() -> void:
	# Pega a posição global do mouse
	var mouse_raw_pos = get_global_mouse_position()
	
	# Calcula a área visível da tela baseada no zoom
	var tamanho_tela = get_viewport_rect().size
	var area_visivel = tamanho_tela / camera.zoom
	
	# Define as bordas máximas e mínimas da câmera
	var limite_min = camera.get_screen_center_position() - (area_visivel / 2.0)
	var limite_max = camera.get_screen_center_position() + (area_visivel / 2.0)
	
	# Cria o vetor final limitando a posição do mouse às bordas
	var posicao_travada = Vector2.ZERO
	posicao_travada.x = clamp(mouse_raw_pos.x, limite_min.x, limite_max.x)
	posicao_travada.y = clamp(mouse_raw_pos.y, limite_min.y, limite_max.y)
	
	# Aplica diretamente na posição GLOBAL do Marker para ignorar a rotação do Player
	cursor_marker.global_position = posicao_travada

func _unhandled_input(event: InputEvent) -> void:
	# [Lógica do Zoom]
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom_value += ZOOM_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom_value -= ZOOM_STEP
		target_zoom_value = clamp(target_zoom_value, MIN_ZOOM, MAX_ZOOM)
	
	# [Lógica de Criar a Broca]
	if event.is_action_pressed("instanciar_broca"):
		_criar_nova_broca()

func _criar_nova_broca() -> void:
	if CENA_BROCA:
		var nova_broca = CENA_BROCA.instantiate()
		get_tree().current_scene.add_child(nova_broca)
		
		# A broca agora nasce exatamente onde o seu $Marker está posicionado no mundo!
		nova_broca.global_position = cursor_marker.global_position
