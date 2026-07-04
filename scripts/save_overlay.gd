class_name SaveOverlay extends RefCounted

const CENA_CARREGANDO = preload("res://scenes/carregando.tscn")

var _save_manager: Node
var _loading: Node = null


func setup(save_manager: Node) -> void:
	_save_manager = save_manager


func mostrar_carregando() -> void:
	if _loading != null:
		return
	var arvore := _save_manager.get_tree()
	if arvore == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 1.0)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)
	var tela := CENA_CARREGANDO.instantiate()
	layer.add_child(tela)
	_loading = layer
	_save_manager.add_child(_loading)
	arvore.paused = true


func esconder_carregando() -> void:
	if _loading != null:
		_loading.queue_free()
		_loading = null
	var arvore := _save_manager.get_tree()
	if arvore != null:
		arvore.paused = false


func esta_ativo() -> bool:
	return _loading != null
