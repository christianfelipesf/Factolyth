class_name CursorInputModule extends RefCounted

signal confirmou(world_pos: Vector2)
signal cancelou(world_pos: Vector2)
signal rotacionou()
signal ui_botao_acionado()

enum InputMode { MOUSE, TOUCH, GAMEPAD }

var _cursor: Node
var _camera: Camera2D
var _joystick: Control
var _input_mode: int = InputMode.MOUSE

var _touch_start_pos: Vector2 = Vector2.INF
var _touch_prev_pos: Vector2 = Vector2.INF
var _touch_start_tempo: float = 0.0
var _touch_arrastando: bool = false
var _touch_foi_arrasto: bool = false
var _touch_emulado: bool = false
var _ultimo_mouse_tempo: float = -INF

const DRAG_LIMIAR := 10.0
const TAP_TEMPO_MINIMO := 0.15
const TEMPO_EMULACAO := 0.05

var _pan_offset: Vector2 = Vector2.ZERO


func setup(cursor: Node) -> void:
	_cursor = cursor
	_camera = cursor.camera
	_joystick = cursor._joystick


func screen_para_mundo(pos: Vector2) -> Vector2:
	var vp = _cursor.get_viewport()
	var tam = vp.get_visible_rect().size
	return _camera.get_screen_center_position() + (pos - tam * 0.5) / _camera.zoom


func process_physics(delta: float, tem_item: bool, pos_grid: Vector2, ultima_pos: Vector2) -> void:
	if _pan_offset != Vector2.ZERO and not _touch_arrastando:
		_pan_offset = _pan_offset.lerp(Vector2.ZERO, 5.0 * delta)
		if _pan_offset.length() < 1.0:
			_pan_offset = Vector2.ZERO
		_camera.offset = _pan_offset

	if not tem_item or _cursor._arrastando_joystick() or _cursor._em_pinça():
		return

	if _input_mode != InputMode.TOUCH:
		if Input.is_action_just_pressed("confirmar") and not _cursor._cursor_em_ui():
			confirmou.emit(pos_grid)

	if Input.is_action_pressed("cancelar") and pos_grid != ultima_pos and not _cursor._modo_destruir:
		cancelou.emit(pos_grid)


func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_ultimo_mouse_tempo = Time.get_ticks_msec() / 1000.0
		_input_mode = InputMode.MOUSE

	if event is InputEventMouseMotion:
		if _input_mode == InputMode.TOUCH and _touch_prev_pos != Vector2.INF:
			_input_mode = InputMode.MOUSE

	if event is InputEventScreenTouch:
		if event.pressed and event.index == 0:
			_touch_emulado = (Time.get_ticks_msec() / 1000.0 - _ultimo_mouse_tempo) < TEMPO_EMULACAO
			_input_mode = InputMode.TOUCH
			_touch_start_pos = event.position
			_touch_prev_pos = event.position
			_touch_start_tempo = Time.get_ticks_msec() / 1000.0
			_touch_arrastando = false
		elif not event.pressed and event.index == 0:
			_touch_foi_arrasto = _touch_arrastando
			_touch_arrastando = false
			_touch_start_pos = Vector2.INF
			_touch_prev_pos = Vector2.INF

	if event is InputEventScreenDrag and event.index == 0:
		if _touch_start_pos != Vector2.INF and not _cursor._arrastando_joystick():
			if not _touch_arrastando and event.position.distance_to(_touch_start_pos) > DRAG_LIMIAR:
				_touch_arrastando = true
			if _touch_arrastando:
				var dp = (event.position - _touch_prev_pos) / _camera.zoom
				_pan_offset -= dp
				_camera.offset = _pan_offset
				_touch_prev_pos = event.position


func handle_unhandled(event: InputEvent) -> void:
	if _cursor.get_tree().paused:
		return

	if event.is_action_pressed("rotacionar_objeto") and _cursor.item_atual != null:
		rotacionou.emit()
		_input_handled()
		return

	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X:
		if _cursor._cursor_em_ui():
			ui_botao_acionado.emit()
			_input_handled()
			return

	if _cursor.item_atual == null:
		return

	if event is InputEventJoypadButton:
		if event.button_index in [JOY_BUTTON_A, JOY_BUTTON_X] and event.pressed:
			if not _cursor._cursor_em_ui():
				confirmou.emit(_cursor._posicao_grid)
				_input_handled()
		elif event.button_index == JOY_BUTTON_B and event.pressed:
			if not _cursor._cursor_em_ui():
				cancelou.emit(_cursor._posicao_grid)
				_input_handled()

	if event is InputEventScreenTouch and not event.pressed and event.index == 0:
		if _touch_foi_arrasto:
			_input_handled()
			return
		if not _touch_emulado and Time.get_ticks_msec() / 1000.0 - _touch_start_tempo < TAP_TEMPO_MINIMO:
			_input_handled()
			return
		if _cursor._arrastando_joystick() or _cursor._em_pinça():
			_input_handled()
			return
		if _joystick != null and _joystick.has_method("is_na_area_de_ui") and _joystick.is_na_area_de_ui(event.position):
			_input_handled()
			return
		if not _cursor._cursor_em_ui(event.position):
			confirmou.emit(screen_para_mundo(event.position))
			_input_handled()


func _input_handled() -> void:
	var vp := _cursor.get_viewport()
	if vp != null:
		vp.set_input_as_handled()