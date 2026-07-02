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

# --- 🌟 NOVAS CONFIGURAÇÕES MODULARES DE CONSTRUÇÃO ---
@export var recurso_esteira: ItemConstrucao
@export var recurso_broca: ItemConstrucao

@onready var target_zoom_value: float = (MIN_ZOOM + MAX_ZOOM) / 2.0
@onready var camera: Camera2D = $Camera2D 
@onready var marker: Marker2D = $Marker2D # Pega a referência do seu cursor modular

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

func _unhandled_input(event: InputEvent) -> void:
	# [Lógica do Zoom]
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom_value += ZOOM_STEP
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom_value -= ZOOM_STEP
		target_zoom_value = clamp(target_zoom_value, MIN_ZOOM, MAX_ZOOM)

	# [🌟 SELEÇÃO DOS ITENS VIA RECURSOS]
	# Certifique-se de que esses nomes de Input Actions ("selecionar_esteira", etc.) 
	# batem com o que você configurou no seu Input Map!
	if event.is_action_pressed("selecionar_esteira") and recurso_esteira != null:
		marker.equipar_item(recurso_esteira)
		print("Modular: Esteira equipada no cursor.")
		
	elif event.is_action_pressed("selecionar_broca") and recurso_broca != null:
		marker.equipar_item(recurso_broca)
		print("Modular: Broca equipada no cursor.")
