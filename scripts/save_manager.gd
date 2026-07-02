extends Node

const DIR_SAVES := "user://saves/"
var _carregando := false
var _loading: Node = null

const CENA_CARREGANDO := preload("res://scenes/carregando.tscn")

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(DIR_SAVES)
	print("SaveManager pronto — F5=salvar, F9=carregar, F12=deletar saves")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("salvar_jogo"):
		salvar("slot_1")
	elif Input.is_action_just_pressed("carregar_jogo"):
		carregar("slot_1")
	elif Input.is_action_just_pressed("deletar_saves"):
		deletar_todos_saves()

func salvar(slot: String) -> void:
	var path := DIR_SAVES + slot + ".json"
	var dados: Dictionary = {
		seed = _obter_semente(),
		estruturas = _coletar_estruturas(),
		jogador = _coletar_jogador()
	}
	var json_str: String = JSON.stringify(dados, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: erro ao abrir ", path, " — ", error_string(FileAccess.get_open_error()))
		return
	file.store_string(json_str)
	print("Salvo em ", path)

func carregar(slot: String) -> void:
	if _carregando:
		return
	_carregando = true
	mostrar_carregando()

	var path := DIR_SAVES + slot + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: erro ao abrir ", path, " — ", error_string(FileAccess.get_open_error()))
		_carregando = false
		esconder_carregando()
		return

	var json_str: String = file.get_as_text()
	var dados: Dictionary = JSON.parse_string(json_str)
	if dados.is_empty():
		_carregando = false
		esconder_carregando()
		return

	var cena: Node = get_tree().current_scene

	_limpar_estruturas(cena)

	await _aplicar_semente(dados.seed, dados.estruturas)

	if dados.has("jogador"):
		_restaurar_jogador(dados.jogador)

	esconder_carregando()
	_carregando = false

func deletar_todos_saves() -> void:
	var dir := DirAccess.open(DIR_SAVES)
	if dir == null:
		return
	dir.list_dir_begin()
	var arquivo := dir.get_next()
	while arquivo != "":
		if arquivo.ends_with(".json"):
			dir.remove(arquivo)
		arquivo = dir.get_next()
	dir.list_dir_end()
	print("Todos os saves deletados")

func mostrar_carregando() -> void:
	if _loading != null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.9)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fundo)
	var tela := CENA_CARREGANDO.instantiate()
	layer.add_child(tela)
	_loading = layer
	add_child(_loading)
	get_tree().paused = true

func esconder_carregando() -> void:
	if _loading != null:
		_loading.queue_free()
		_loading = null
	get_tree().paused = false

func _obter_semente() -> int:
	var mapa := get_tree().current_scene.get_node_or_null("Mapa")
	return mapa.semente if mapa else 0

func _aplicar_semente(semente: int, estruturas: Array) -> void:
	var mapa := get_tree().current_scene.get_node_or_null("Mapa")
	if mapa == null:
		return
	mapa.semente = semente
	await mapa.gerar()

	for est in estruturas:
		_instanciar_estrutura(est)

func _coletar_jogador() -> Dictionary:
	var jogador := get_tree().current_scene.get_node_or_null("Jogador/player")
	if jogador == null or not jogador.has_method("get_save_data"):
		return {}
	return jogador.get_save_data()

func _restaurar_jogador(dados: Dictionary) -> void:
	var jogador := get_tree().current_scene.get_node_or_null("Jogador/player")
	if jogador == null or not jogador.has_method("set_save_data"):
		return
	jogador.set_save_data(dados)

func _coletar_estruturas() -> Array:
	var lista: Array = []
	for node in get_tree().get_nodes_in_group("estrutura"):
		var entry: Dictionary = {
			cena = node.scene_file_path,
			posicao = [node.global_position.x, node.global_position.y],
			rotacao = rad_to_deg(node.global_rotation)
		}
		if node.has_method("get_save_data"):
			entry.dados = node.get_save_data()
		lista.append(entry)
	return lista

func _limpar_estruturas(cena: Node) -> void:
	for node in get_tree().get_nodes_in_group("estrutura"):
		if is_instance_valid(node):
			node.queue_free()
	await get_tree().physics_frame

func _instanciar_estrutura(dados: Dictionary) -> void:
	var cena_obj := load(dados.cena) as PackedScene
	if cena_obj == null:
		push_error("SaveManager: cena nao encontrada: ", dados.cena)
		return
	var inst := cena_obj.instantiate()
	var pos_array: Array = dados.posicao
	inst.global_position = Vector2(pos_array[0], pos_array[1])
	inst.global_rotation = deg_to_rad(dados.rotacao)
	if inst.has_method("set_save_data") and dados.has("dados"):
		inst.set_save_data(dados.dados)
	get_tree().current_scene.add_child(inst)
	inst.add_to_group("estrutura")
