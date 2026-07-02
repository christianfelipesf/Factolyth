extends Marker2D

# O cursor agora só se importa com QUAL recurso está ativo
var item_atual: ItemConstrucao = null
var rotation_atual: float = 0.0
var _ultima_posicao_colocacao: Vector2 = Vector2.INF

@onready var camera: Camera2D = $"../Camera2D"
@onready var area_checagem: Area2D = $AreaChecagem

func _ready() -> void:
	for filho in get_children():
		if filho is CanvasItem:
			filho.z_index = 10

func _physics_process(_delta: float) -> void:
	global_rotation = 0.0
	_atualizar_posicao_marker_no_grid()
	
	if not Input.is_action_pressed("instanciar_objeto") and not Input.is_action_pressed("remover_objeto"):
		_ultima_posicao_colocacao = Vector2.INF
	
	if item_atual != null:
		if Input.is_action_pressed("instanciar_objeto"):
			if global_position != _ultima_posicao_colocacao and not _area_esta_ocupada():
				_criar_objeto_posicionavel()
		elif Input.is_action_pressed("remover_objeto"):
			_remover_objeto_na_posicao()

# FUNÇÃO PÚBLICA: Chame isso a partir dos seus botões de inventário ou UI!
func equipar_item(novo_item: ItemConstrucao) -> void:
	item_atual = novo_item
	rotation_atual = 0.0
	_ultima_posicao_colocacao = Vector2.INF
	_atualizar_preview_visual()

func desequipar_item() -> void:
	item_atual = null
	_ultima_posicao_colocacao = Vector2.INF
	_atualizar_preview_visual()

func _atualizar_posicao_marker_no_grid() -> void:
	var mouse_raw_pos = get_global_mouse_position()
	var tamanho_tela = get_viewport_rect().size
	var area_visivel = tamanho_tela / camera.zoom
	
	var limite_min = camera.get_screen_center_position() - (area_visivel / 2.0)
	var limite_max = camera.get_screen_center_position() + (area_visivel / 2.0)
	
	var pos_travada = Vector2(
		clamp(mouse_raw_pos.x, limite_min.x, limite_max.x),
		clamp(mouse_raw_pos.y, limite_min.y, limite_max.y)
	)
	
	global_position = Vector2(floor(pos_travada.x / 32.0) * 32.0 + 16, floor(pos_travada.y / 32.0) * 32.0 + 16)
	_gerenciar_cor_do_preview()

func _area_esta_ocupada() -> bool:
	return area_checagem.has_overlapping_bodies()

func _gerenciar_cor_do_preview() -> void:
	if item_atual == null:
		return
	var ocupado = _area_esta_ocupada()
	for filho in get_children():
		if filho.has_meta("is_construction_preview"):
			filho.modulate = Color(1.0, 0.3, 0.3, 0.5) if ocupado else Color(1.0, 1.0, 1.0, 0.4)

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
	if "is_preview" in obj_temp: obj_temp.is_preview = true
	
	var sprite = obj_temp.find_child("*AnimatedSprite2D*", true, false)
	if sprite == null: sprite = obj_temp.find_child("*Sprite2D*", true, false)
	
	if sprite != null:
		var preview = sprite.duplicate() as CanvasItem
		preview.set_meta("is_construction_preview", true)
		preview.modulate.a = 0.4
		preview_no_set_rotation(preview)
		add_child(preview)
		if preview.has_method("play"): preview.play()
			
	obj_temp.queue_free()

func preview_no_set_rotation(preview: CanvasItem) -> void:
	var offset = -90.0 if item_atual.compensar_rotacao_90 else 0.0
	preview.rotation = deg_to_rad(rotation_atual + offset)

func _criar_objeto_posicionavel() -> void:
	var novo_objeto = item_atual.cena_objeto.instantiate()
	if "is_preview" in novo_objeto: novo_objeto.is_preview = false
	if "esta_posicionando" in novo_objeto: novo_objeto.esta_posicionando = false
		
	var offset = -90.0 if item_atual.compensar_rotacao_90 else 0.0
	novo_objeto.global_rotation = deg_to_rad(rotation_atual + offset)
	
	get_tree().current_scene.add_child(novo_objeto)
	novo_objeto.global_position = global_position

	_ultima_posicao_colocacao = global_position

	await get_tree().physics_frame

	get_tree().call_group("broca", "verificar_extrutura_e_atualizar_estado")

func _remover_objeto_na_posicao() -> void:
	for corpo in area_checagem.get_overlapping_bodies():
		if corpo != $"..": corpo.queue_free()
