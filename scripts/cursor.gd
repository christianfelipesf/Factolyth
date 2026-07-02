extends Marker2D

const PARTICULA = preload("res://scenes/particles/particula.tscn")

var item_atual: ItemConstrucao = null
var rotation_atual: float = 0.0
var _posicao_grid: Vector2 = Vector2.ZERO
var _ultima_posicao_colocacao: Vector2 = Vector2.INF
var _indicador_grid: Sprite2D = null
var _tamanho_grid_atual: Vector2i = Vector2i(1, 1)

@onready var camera: Camera2D = $"../Camera2D"
@onready var area_checagem: Area2D = $AreaChecagem
@onready var shape_checagem: CollisionShape2D = $AreaChecagem/CollisionShape2D

func _ready() -> void:
	for filho in get_children():
		if filho is CanvasItem:
			filho.z_index = 10

	_recriar_indicador(Vector2i(1, 1))

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

func _physics_process(_delta: float) -> void:
	global_rotation = 0.0
	_atualizar_cursor_e_grid()

	if not Input.is_action_pressed("instanciar_objeto") and not Input.is_action_pressed("remover_objeto"):
		_ultima_posicao_colocacao = Vector2.INF

	if item_atual != null:
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
	_atualizar_preview_visual()

func _atualizar_cursor_e_grid() -> void:
	var mouse_pos := get_global_mouse_position()
	var tam_tela := get_viewport_rect().size
	var area_visivel := tam_tela / camera.zoom
	var centro := camera.get_screen_center_position()
	var lim_min := centro - area_visivel / 2.0
	var lim_max := centro + area_visivel / 2.0

	global_position = Vector2(
		clamp(mouse_pos.x, lim_min.x, lim_max.x),
		clamp(mouse_pos.y, lim_min.y, lim_max.y)
	)

	_posicao_grid = Vector2(
		floor(mouse_pos.x / 32.0) * 32.0 + 16,
		floor(mouse_pos.y / 32.0) * 32.0 + 16
	)

	var ofs := _offset_colocacao()

	if _indicador_grid != null:
		_indicador_grid.global_position = _posicao_grid + ofs

	area_checagem.global_position = _posicao_grid + ofs

	for child in get_children():
		if child.has_meta("is_construction_preview"):
			child.global_position = _posicao_grid + ofs

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancelar_construcao"):
		desequipar_item()
	elif event.is_action_pressed("rotacionar_objeto") and item_atual != null:
		rotation_atual = fmod(rotation_atual + 90.0, 360.0)
		_atualizar_preview_visual()
		get_viewport().set_input_as_handled()

func _atualizar_preview_visual() -> void:
	for child in get_children():
		if child.has_meta("is_construction_preview"):
			child.queue_free()

	if item_atual == null or item_atual.cena_objeto == null:
		return

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
			corpo.queue_free()
