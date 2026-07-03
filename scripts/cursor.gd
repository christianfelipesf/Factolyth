extends Marker2D

const PARTICULA = preload("res://scenes/particles/particula.tscn")
const VELOCIDADE_CURSOR := 600.0
const DEADZONE := 0.2

var item_atual: ItemConstrucao = null
var rotation_atual: float = 0.0
var _posicao_grid: Vector2 = Vector2.ZERO
var _ultima_posicao_colocacao: Vector2 = Vector2.INF
var _indicador_grid: Sprite2D = null
var _tamanho_grid_atual: Vector2i = Vector2i(1, 1)

var _joystick: Control = null
var _cursor_controle: Vector2 = Vector2.ZERO
var _modo_controle: bool = false
var _mouse_moveu: bool = false
var _warpeando: bool = false

@onready var camera: Camera2D = $"../Camera2D"
@onready var area_checagem: Area2D = $AreaChecagem
@onready var shape_checagem: CollisionShape2D = $AreaChecagem/CollisionShape2D
@onready var _audio_ambiente: AudioStreamPlayer = $AudioAmbiente
@onready var _audio_colocar: AudioStreamPlayer = $AudioColocar
@onready var _audio_destruir: AudioStreamPlayer = $AudioDestruir
@onready var _seta_direcao: Polygon2D = $SetaDirecao

func _ready() -> void:
	_joystick = get_tree().root.find_child("Joystick", true, false)
	for filho in get_children():
		if filho is CanvasItem:
			filho.z_index = 10
	_recriar_indicador(Vector2i(1, 1))
	_audio_ambiente.finished.connect(_audio_ambiente.play)
	$Sprite2D.visible = false  # OS cursor substitui visual

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not _warpeando:
		_mouse_moveu = true
	_warpeando = false

func _recriar_indicador(tamanho: Vector2i) -> void:
	if _indicador_grid != null:
		_indicador_grid.queue_free()
		_indicador_grid = null

	var px := tamanho.x * 32
	var py := tamanho.y * 32
	var img := Image.create(px, py, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	_indicador_grid = Sprite2D.new()
	_indicador_grid.texture = tex
	_indicador_grid.modulate = Color(0, 1, 0, 0.18)
	_indicador_grid.z_index = 11
	add_child(_indicador_grid)

	var rect := RectangleShape2D.new()
	rect.size = Vector2(px - 8.0, py - 8.0)
	shape_checagem.shape = rect

func _offset_colocacao() -> Vector2:
	return Vector2(
		(_tamanho_grid_atual.x - 1) * 16.0,
		(_tamanho_grid_atual.y - 1) * 16.0
	)

func _physics_process(delta: float) -> void:
	global_rotation = 0.0

	var stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)

	if stick.length() > DEADZONE:
		if not _modo_controle:
			var mouse_tela := get_viewport().get_mouse_position()
			_cursor_controle = mouse_tela if mouse_tela != Vector2.ZERO else get_viewport().get_visible_rect().size / 2.0
			_modo_controle = true
		_cursor_controle += stick * VELOCIDADE_CURSOR * delta
		var screen_size := get_viewport().get_visible_rect().size
		_cursor_controle = _cursor_controle.clamp(Vector2.ZERO, screen_size)
	elif _modo_controle and _mouse_moveu:
		_modo_controle = false
	_mouse_moveu = false

	if _modo_controle:
		var screen_size := get_viewport().get_visible_rect().size
		var centro := camera.get_screen_center_position()
		var world_pos := centro + (_cursor_controle - screen_size / 2.0) / camera.zoom
		_warpeando = true
		Input.warp_mouse(_cursor_controle)
		_atualizar_cursor_e_grid(world_pos)
	else:
		_atualizar_cursor_e_grid()

	if not Input.is_action_pressed("instanciar_objeto") and not Input.is_action_pressed("remover_objeto"):
		_ultima_posicao_colocacao = Vector2.INF

	if item_atual != null and not _arrastando_joystick():
		if Input.is_action_pressed("instanciar_objeto"):
			if _posicao_grid != _ultima_posicao_colocacao and not _area_esta_ocupada():
				_criar_objeto_posicionavel()
		elif Input.is_action_pressed("remover_objeto"):
			_remover_objeto_na_posicao()

func equipar_item(novo_item: ItemConstrucao) -> void:
	item_atual = novo_item
	_tamanho_grid_atual = item_atual.tamanho_grid if item_atual != null else Vector2i(1, 1)
	_recriar_indicador(_tamanho_grid_atual)
	rotation_atual = 0.0
	_ultima_posicao_colocacao = Vector2.INF
	_atualizar_preview_visual()

func desequipar_item() -> void:
	item_atual = null
	_tamanho_grid_atual = Vector2i(1, 1)
	_recriar_indicador(Vector2i(1, 1))
	_ultima_posicao_colocacao = Vector2.INF
	_seta_direcao.visible = false
	_atualizar_preview_visual()

func _atualizar_cursor_e_grid(pos_alternativa: Vector2 = Vector2.INF) -> void:
	var alvo: Vector2
	if pos_alternativa != Vector2.INF:
		alvo = pos_alternativa
	else:
		alvo = get_global_mouse_position()

	var tam_tela := get_viewport_rect().size
	var area_visivel := tam_tela / camera.zoom
	var centro := camera.get_screen_center_position()
	var lim_min := centro - area_visivel / 2.0
	var lim_max := centro + area_visivel / 2.0

	global_position = Vector2(
		clamp(alvo.x, lim_min.x, lim_max.x),
		clamp(alvo.y, lim_min.y, lim_max.y)
	)

	_posicao_grid = Vector2(
		floor(alvo.x / 32.0) * 32.0 + 16,
		floor(alvo.y / 32.0) * 32.0 + 16
	)

	var ofs := _offset_colocacao()

	if _indicador_grid != null:
		_indicador_grid.global_position = _posicao_grid + ofs

	area_checagem.global_position = _posicao_grid + ofs

	for child in get_children():
		if child.has_meta("is_construction_preview"):
			child.global_position = _posicao_grid + ofs

	if _seta_direcao.visible:
		_seta_direcao.global_position = _posicao_grid + ofs

	_gerenciar_cor_do_preview()

func _area_esta_ocupada() -> bool:
	return area_checagem.has_overlapping_bodies()

func _gerenciar_cor_do_preview() -> void:
	if item_atual == null:
		return
	var ocupado := _area_esta_ocupada()
	var cor := Color(1.0, 0.3, 0.3, 0.5) if ocupado else Color(1.0, 1.0, 1.0, 0.4)
	if _indicador_grid != null:
		_indicador_grid.modulate = Color(1.0, 0.0, 0.0, 0.18) if ocupado else Color(0.0, 1.0, 0.0, 0.18)
	for filho in get_children():
		if filho.has_meta("is_construction_preview"):
			filho.modulate = cor

func _arrastando_joystick() -> bool:
	return _joystick != null and _joystick.has_method("esta_arrastando") and _joystick.esta_arrastando()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar_construcao"):
		desequipar_item()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rotacionar_objeto") and item_atual != null:
		rotation_atual = fmod(rotation_atual + 90.0, 360.0)
		_atualizar_preview_visual()
		get_viewport().set_input_as_handled()

	if item_atual == null:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _arrastando_joystick():
			if not _area_esta_ocupada():
				_criar_objeto_posicionavel()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_remover_objeto_na_posicao()
			get_viewport().set_input_as_handled()

	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_A and event.pressed:
			if not _area_esta_ocupada():
				_criar_objeto_posicionavel()
			get_viewport().set_input_as_handled()
		elif event.button_index == JOY_BUTTON_B and event.pressed:
			_remover_objeto_na_posicao()
			get_viewport().set_input_as_handled()

func _atualizar_preview_visual() -> void:
	for child in get_children():
		if child.has_meta("is_construction_preview"):
			child.queue_free()

	if item_atual == null or item_atual.cena_objeto == null:
		_seta_direcao.visible = false
		return

	_seta_direcao.visible = true
	_seta_direcao.rotation = deg_to_rad(rotation_atual)

	var obj_temp = item_atual.cena_objeto.instantiate()
	if "is_preview" in obj_temp:
		obj_temp.is_preview = true

	var sprite = obj_temp.find_child("*AnimatedSprite2D*", true, false)
	if sprite == null:
		sprite = obj_temp.find_child("*Sprite2D*", true, false)

	if sprite != null:
		var preview = sprite.duplicate() as CanvasItem
		preview.set_meta("is_construction_preview", true)
		preview.modulate.a = 0.4
		preview_no_set_rotation(preview)
		preview.global_position = _posicao_grid + _offset_colocacao()
		add_child(preview)
		if preview.has_method("play"):
			preview.play()

	obj_temp.queue_free()

func preview_no_set_rotation(preview: CanvasItem) -> void:
	var offset = -90.0 if item_atual.compensar_rotacao_90 else 0.0
	preview.rotation = deg_to_rad(rotation_atual + offset)

func _criar_objeto_posicionavel() -> void:
	var novo_objeto = item_atual.cena_objeto.instantiate()
	if "is_preview" in novo_objeto:
		novo_objeto.is_preview = false
	if "esta_posicionando" in novo_objeto:
		novo_objeto.esta_posicionando = false

	var offset = -90.0 if item_atual.compensar_rotacao_90 else 0.0
	novo_objeto.global_rotation = deg_to_rad(rotation_atual + offset)

	novo_objeto.global_position = _posicao_grid + _offset_colocacao()
	get_tree().current_scene.add_child(novo_objeto)
	novo_objeto.add_to_group("estrutura")
	_spawnar_particula(novo_objeto.global_position)
	_audio_colocar.play()

	_ultima_posicao_colocacao = _posicao_grid

	await get_tree().physics_frame

	get_tree().call_group("broca", "verificar_extrutura_e_atualizar_estado")

func _spawnar_particula(pos: Vector2) -> void:
	var p = PARTICULA.instantiate()
	p.global_position = pos
	p.one_shot = true
	get_tree().current_scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

func _remover_objeto_na_posicao() -> void:
	for corpo in area_checagem.get_overlapping_bodies():
		if corpo != $"..":
			_spawnar_particula(corpo.global_position)
			_audio_destruir.play()
			corpo.queue_free()
