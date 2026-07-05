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
var _barra_ui_root: Control = null
var _ui_root: Control = null
var _cursor_controle: Vector2 = Vector2.ZERO
var _modo_controle: bool = false
var _mouse_moveu: bool = false
var _warpeando: bool = false

var _grid_module: CursorGridModule
var _preview_module: CursorPreviewModule
var _placement_module: CursorPlacementModule

@onready var camera: Camera2D = $"../Camera2D"
@onready var area_checagem: Area2D = $AreaChecagem
@onready var shape_checagem: CollisionShape2D = $AreaChecagem/CollisionShape2D
@onready var _audio_ambiente: AudioStreamPlayer = $AudioAmbiente
@onready var _audio_colocar: AudioStreamPlayer = $AudioColocar
@onready var _audio_destruir: AudioStreamPlayer = $AudioDestruir
@onready var _seta_direcao: Polygon2D = $SetaDirecao


func _ready() -> void:
	_grid_module = CursorGridModule.new()
	_preview_module = CursorPreviewModule.new()
	_placement_module = CursorPlacementModule.new()
	_grid_module.setup(self)
	_preview_module.setup(self)
	_placement_module.setup(self)

	_joystick = get_tree().root.find_child("Joystick", true, false)
	_ui_root = get_tree().root.find_child("UI", true, false)
	_botao_pausa = get_tree().root.find_child("BotaoPausa", true, false)
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
		_grid_module.atualizar_cursor_e_grid(world_pos)
	else:
		_grid_module.atualizar_cursor_e_grid()

	if get_tree().paused:
		return

	if not Input.is_action_pressed("confirmar") and not Input.is_action_pressed("cancelar"):
		_ultima_posicao_colocacao = Vector2.INF

	if item_atual != null and not _arrastando_joystick() and not _em_pinça():
		var quer_instanciar := Input.is_action_just_pressed("confirmar")

		if not quer_instanciar:
			quer_instanciar = Input.is_action_pressed("confirmar") and _posicao_grid != _ultima_posicao_colocacao
			if Input.is_action_pressed("cancelar") and _posicao_grid != _ultima_posicao_colocacao:
				_placement_module.remover_objeto_na_posicao(true)
				_ultima_posicao_colocacao = _posicao_grid

		if quer_instanciar and not _cursor_em_ui():
			if _eh_broca_manual() or not _grid_module.area_esta_ocupada():
				_criar_objeto_posicionavel()
				_ultima_posicao_colocacao = _posicao_grid


func _eh_broca_manual() -> bool:
	return item_atual != null and item_atual.nome == "BrocaManual"


func equipar_item(novo_item: ItemConstrucao) -> void:
	item_atual = novo_item
	_tamanho_grid_atual = item_atual.tamanho_grid if item_atual != null else Vector2i(1, 1)
	_grid_module.recriar_indicador(_tamanho_grid_atual)
	rotation_atual = 0.0
	_ultima_posicao_colocacao = Vector2.INF
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


func _cursor_em_ui() -> bool:
	var mouse_pos := get_viewport().get_mouse_position()

	if _joystick != null and _joystick.has_method("is_na_area_de_ui") and _joystick.is_na_area_de_ui(mouse_pos):
		return true
	if _botao_pausa != null and _botao_pausa.get_global_rect().has_point(mouse_pos):
		return true
	if _barra_ui_root != null and _barra_ui_root.get_global_rect().has_point(mouse_pos):
		return true

	var hud = get_node_or_null("/root/Mundo/Playerui/UI/CraftingHUD")
	if hud != null and hud.visible:
		return true

	return false


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if event.is_action_pressed("cancelar"):
		if not _cursor_em_ui():
			_placement_module.remover_objeto_na_posicao(true)
		_input_handled()
		return
	elif event.is_action_pressed("rotacionar_objeto") and item_atual != null:
		rotation_atual = fmod(rotation_atual + 90.0, 360.0)
		_preview_module.atualizar_preview_visual()
		_input_handled()
		return

	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
		if _cursor_em_ui():
			var focused = get_viewport().gui_get_focus_owner()
			if focused is Button:
				focused.pressed.emit()
				_input_handled()
				return

	if item_atual == null:
		return

	if event is InputEventJoypadButton:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_X] and event.pressed:
			if not _cursor_em_ui():
				if _eh_broca_manual() or not _grid_module.area_esta_ocupada():
					_criar_objeto_posicionavel()
				_input_handled()
		elif event.button_index == JOY_BUTTON_B and event.pressed:
			if not _cursor_em_ui():
				_placement_module.remover_objeto_na_posicao(true)
				_input_handled()

	if event is InputEventScreenTouch and event.pressed and event.index == 0:
		if not _cursor_em_ui() and not _arrastando_joystick() and not _em_pinça():
			var screen_size: Vector2 = get_viewport().get_visible_rect().size
			var centro: Vector2 = camera.get_screen_center_position()
			var offset: Vector2 = (event.position - screen_size * 0.5) / Vector2(camera.zoom.x, camera.zoom.y)
			var world_pos: Vector2 = centro + offset
			_grid_module.atualizar_cursor_e_grid(world_pos)
			if _eh_broca_manual() or not _grid_module.area_esta_ocupada():
				_criar_objeto_posicionavel()
			_input_handled()


func _input_handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _criar_objeto_posicionavel() -> void:
	_placement_module.criar_objeto_posicionavel()
