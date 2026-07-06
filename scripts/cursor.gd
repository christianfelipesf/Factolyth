extends Marker2D

const VELOCIDADE_CURSOR := 600.0
const DEADZONE := 0.2

var item_atual: ItemConstrucao = null
var rotation_atual: float = 0.0
var _posicao_grid: Vector2 = Vector2.ZERO
var _ultima_posicao_colocacao: Vector2 = Vector2.INF
var _indicador_grid: Sprite2D = null
var _tamanho_grid_atual: Vector2i = Vector2i(1, 1)

var _joystick: Control = null
var _botao_pausa: Control = null
var _botao_craft: Control = null
var _botao_modo: Control = null
var _botao_rotacionar: Control = null
var _botao_confirmar: Control = null
var _botao_cancelar: Control = null
var _barra_ui_root: Control = null
var _ui_root: Control = null
var _cursor_controle: Vector2 = Vector2.ZERO
var _modo_controle: bool = false
var _mouse_moveu: bool = false
var _warpeando: bool = false

var _modo_destruir: bool = false

var _grid_module: CursorGridModule
var _preview_module: CursorPreviewModule
var _placement_module: CursorPlacementModule
var _input_module: CursorInputModule
var _pending_module: PendingPlacementModule

@onready var camera: Camera2D = $"../Camera2D"
@onready var area_checagem: Area2D = $AreaChecagem
@onready var shape_checagem: CollisionShape2D = $AreaChecagem/CollisionShape2D
@onready var _audio_ambiente: AudioStreamPlayer = $AudioAmbiente
@onready var _audio_colocar: AudioStreamPlayer = $AudioColocar
@onready var _audio_destruir: AudioStreamPlayer = $AudioDestruir
@onready var _seta_direcao: Polygon2D = $SetaDirecao


func _ready() -> void:
	add_to_group("cursor")
	_grid_module = CursorGridModule.new()
	_preview_module = CursorPreviewModule.new()
	_placement_module = CursorPlacementModule.new()
	_pending_module = PendingPlacementModule.new()
	_grid_module.setup(self)
	_preview_module.setup(self)
	_placement_module.setup(self)
	_pending_module.setup(self)

	_input_module = CursorInputModule.new()
	_input_module.setup(self)
	_input_module.confirmou.connect(_on_input_confirmou)
	_input_module.cancelou.connect(_on_input_cancelou)
	_input_module.rotacionou.connect(_on_input_rotacionou)

	_joystick = get_tree().root.find_child("Joystick", true, false)
	_ui_root = get_tree().root.find_child("UI", true, false)
	_botao_pausa = get_tree().root.find_child("BotaoPausa", true, false)
	_botao_craft = get_tree().root.find_child("BotaoCraft", true, false)
	_botao_modo = get_tree().root.find_child("BotaoModo", true, false)
	_botao_rotacionar = get_tree().root.find_child("BotaoRotacionar", true, false)
	_botao_confirmar = get_tree().root.find_child("BotaoConfirmar", true, false)
	_botao_cancelar = get_tree().root.find_child("BotaoCancelar", true, false)
	_barra_ui_root = get_tree().root.find_child("BarraConstrucao", true, false)
	for filho in get_children():
		if filho is CanvasItem:
			filho.z_index = 10
	_grid_module.recriar_indicador(Vector2i(1, 1))
	_audio_ambiente.finished.connect(_audio_ambiente.play)
	$Sprite2D.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not _warpeando:
		_mouse_moveu = true
	_warpeando = false
	_input_module.handle_input(event)


func _unhandled_input(event: InputEvent) -> void:
	_input_module.handle_unhandled(event)


func _hud_craft_visivel() -> bool:
	var hud = get_node_or_null("/root/Mundo/Playerui/UI/CraftingHUD")
	return hud != null and hud.visible


func _physics_process(delta: float) -> void:
	global_rotation = 0.0

	_input_module.process_physics(delta, item_atual != null, _posicao_grid, _ultima_posicao_colocacao)

	if _hud_craft_visivel():
		if _modo_controle:
			_modo_controle = false
		_mouse_moveu = false
		_grid_module.atualizar_cursor_e_grid()
		if get_tree().paused:
			return
		return

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
		_grid_module.atualizar_cursor_e_grid(world_pos)
	else:
		_grid_module.atualizar_cursor_e_grid()

	if get_tree().paused:
		return

	if not Input.is_action_pressed("confirmar") and not Input.is_action_pressed("cancelar"):
		_ultima_posicao_colocacao = Vector2.INF


func _on_input_confirmou(world_pos: Vector2) -> void:
	_grid_module.atualizar_cursor_e_grid(world_pos)
	if _modo_destruir:
		_placement_module.remover_objeto_na_posicao(true)
	elif _eh_broca_manual() or not _grid_module.area_esta_ocupada():
		_criar_objeto_posicionavel()
		_ultima_posicao_colocacao = _posicao_grid


func _on_input_cancelou(world_pos: Vector2) -> void:
	_grid_module.atualizar_cursor_e_grid(world_pos)
	_placement_module.remover_objeto_na_posicao(true)
	_ultima_posicao_colocacao = _posicao_grid


func _on_input_rotacionou() -> void:
	rotation_atual = fmod(rotation_atual + 90.0, 360.0)
	_preview_module.atualizar_preview_visual()


func _eh_broca_manual() -> bool:
	return item_atual != null and item_atual.nome == "BrocaManual"


func alternar_modo_destruir() -> void:
	_modo_destruir = not _modo_destruir
	_preview_module.atualizar_preview_visual()


func tem_modo_destruir() -> bool:
	return _modo_destruir


func equipar_item(novo_item: ItemConstrucao) -> void:
	item_atual = novo_item
	_tamanho_grid_atual = item_atual.tamanho_grid if item_atual != null else Vector2i(1, 1)
	_grid_module.recriar_indicador(_tamanho_grid_atual)
	rotation_atual = 0.0
	_ultima_posicao_colocacao = Vector2.INF
	if _botao_rotacionar != null:
		_botao_rotacionar.rotation = 0.0
	_preview_module.atualizar_preview_visual()


func desequipar_item() -> void:
	item_atual = null
	_tamanho_grid_atual = Vector2i(1, 1)
	_grid_module.recriar_indicador(Vector2i(1, 1))
	_ultima_posicao_colocacao = Vector2.INF
	_seta_direcao.visible = false
	_preview_module.atualizar_preview_visual()


func _arrastando_joystick() -> bool:
	return _joystick != null and _joystick.has_method("esta_arrastando") and _joystick.esta_arrastando()


func _em_pinça() -> bool:
	var pai: Node = $".."
	return pai.has_method("is_pinçando") and pai.is_pinçando()


func _cursor_em_ui(pos_tela: Vector2 = Vector2.INF) -> bool:
	var pos := pos_tela if pos_tela != Vector2.INF else get_viewport().get_mouse_position()

	# Usar o sistema de GUI do Godot: qualquer Control com mouse_filter STOP na hierarquia
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered != null:
		var ui_pai = _ui_root
		if ui_pai != null and (hovered == ui_pai or ui_pai.is_ancestor_of(hovered)):
			return true

	# Fallback manual para elementos que o gui_get_hovered_control pode não capturar
	if _joystick != null and _joystick.has_method("is_na_area_de_ui") and _joystick.is_na_area_de_ui(pos):
		return true
	if _botao_pausa != null and _ponto_no_controle(_botao_pausa, pos):
		return true
	if _botao_craft != null and _ponto_no_controle(_botao_craft, pos):
		return true
	if _botao_modo != null and _ponto_no_controle(_botao_modo, pos):
		return true
	if _botao_rotacionar != null and _botao_rotacionar.visible and _ponto_no_controle(_botao_rotacionar, pos):
		return true
	if _botao_confirmar != null and _botao_confirmar.visible and _ponto_no_controle(_botao_confirmar, pos):
		return true
	if _botao_cancelar != null and _botao_cancelar.visible and _ponto_no_controle(_botao_cancelar, pos):
		return true
	if _barra_ui_root != null and _ponto_no_controle(_barra_ui_root, pos):
		return true

	var hud = get_node_or_null("/root/Mundo/Playerui/UI/CraftingHUD")
	if hud != null and hud.visible:
		return true

	return false


func _ponto_no_controle(control: Control, ponto: Vector2) -> bool:
	var rect := control.get_global_rect()
	var esc := control.scale
	if esc == Vector2.ONE:
		return rect.has_point(ponto)
	var centro := rect.get_center()
	var tam_visual := rect.size * esc
	var rect_visual := Rect2(centro - tam_visual * 0.5, tam_visual)
	return rect_visual.has_point(ponto)


func _criar_objeto_posicionavel() -> void:
	_placement_module.criar_objeto_posicionavel(true)


func confirmar_pendentes() -> void:
	_pending_module.confirmar_pendentes()


func cancelar_pendentes() -> void:
	_pending_module.cancelar_pendentes()


func tem_pendentes() -> bool:
	return _pending_module.tem_pendentes()


func rotacionar() -> void:
	_on_input_rotacionou()
