extends Node

signal save_concluido(slot: String)
signal save_negado(reason: String)

const DIR_SAVES := "user://saves/"
const SLOT_PADRAO := "slot_1"
const MODO_CRIATIVO := "criativo"
const MODO_SOBREVIVENCIA := "sobrevivencia"
var _carregando := false
var save_pendente: String = ""
var modo_procedural: bool = false
var modo_jogo: String = MODO_CRIATIVO

var _overlay


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_overlay = preload("res://scripts/save_overlay.gd").new()
	_overlay.setup(self)
	var dir_acesso := DirAccess.open("user://")
	if dir_acesso:
		dir_acesso.make_dir_recursive("saves")
	print("SaveManager pronto — F5=salvar, F9=carregar, F12=deletar saves")


func _process(_delta: float) -> void:
	var arvore := get_tree()
	if arvore == null:
		return

	if save_pendente != "":
		var cena := arvore.current_scene
		if cena != null and cena.name != "Main":
			var slot := save_pendente
			save_pendente = ""
			carregar(slot)
			return

	if Input.is_action_just_pressed("salvar_jogo"):
		salvar(SLOT_PADRAO)
	elif Input.is_action_just_pressed("carregar_jogo"):
		carregar(SLOT_PADRAO)
	elif Input.is_action_just_pressed("deletar_saves"):
		deletar_todos_saves()


func salvar(slot: String) -> void:
	if modo_procedural:
		save_negado.emit("Modo procedural: salvamento bloqueado")
		return
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
	save_concluido.emit(slot)


func carregar(slot: String) -> void:
	if _carregando:
		return
	modo_procedural = false
	var arvore := get_tree()
	if arvore == null or arvore.current_scene == null:
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

	_limpar_estruturas(arvore.current_scene)
	await _aplicar_semente(dados.get("seed", 0), dados.get("estruturas", []))

	var mapa := arvore.current_scene.get_node_or_null("Mapa")
	if mapa != null and mapa.has_method("await_chunks_pronto"):
		await mapa.await_chunks_pronto()

	if dados.has("jogador"):
		_restaurar_jogador(dados.jogador)

	esconder_carregando()
	_carregando = false


func deletar_todos_saves() -> void:
	if not DirAccess.dir_exists_absolute(DIR_SAVES):
		return
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
	_overlay.mostrar_carregando()


func esconder_carregando() -> void:
	_overlay.esconder_carregando()


func _obter_semente() -> int:
	var arvore := get_tree()
	if arvore == null or arvore.current_scene == null:
		return 0
	var mapa := arvore.current_scene.get_node_or_null("Mapa")
	return mapa.semente if mapa else 0


func _aplicar_semente(semente: int, estruturas: Array) -> void:
	var arvore := get_tree()
	if arvore == null or arvore.current_scene == null:
		return
	var mapa := arvore.current_scene.get_node_or_null("Mapa")
	if mapa == null:
		return
	mapa.semente = semente
	await mapa.gerar(false)

	for i in range(estruturas.size()):
		_instanciar_estrutura(estruturas[i])
		if i % 10 == 0:
			arvore = get_tree()
			if arvore != null:
				await arvore.process_frame


func _coletar_jogador() -> Dictionary:
	var arvore := get_tree()
	if arvore == null:
		return {}
	var jogador := arvore.get_first_node_in_group("jogador")
	if jogador == null or not jogador.has_method("get_save_data"):
		return {}
	return jogador.get_save_data()


func _restaurar_jogador(dados: Dictionary) -> void:
	var arvore := get_tree()
	if arvore == null:
		return
	var jogador := arvore.get_first_node_in_group("jogador")
	if jogador == null or not jogador.has_method("set_save_data"):
		return
	jogador.set_save_data(dados)


func _coletar_estruturas() -> Array:
	var lista: Array = []
	var arvore := get_tree()
	if arvore == null:
		return lista
	for node in arvore.get_nodes_in_group("estrutura"):
		var entry: Dictionary = {
			cena = node.scene_file_path,
			posicao = [node.global_position.x, node.global_position.y],
			rotacao = rad_to_deg(node.global_rotation)
		}
		if node.has_method("get_save_data"):
			entry.dados = node.get_save_data()
		lista.append(entry)
	return lista


func _limpar_estruturas(_cena: Node) -> void:
	var arvore := get_tree()
	if arvore == null:
		return
	for node in arvore.get_nodes_in_group("estrutura"):
		if is_instance_valid(node):
			node.queue_free()
	arvore = get_tree()
	if arvore != null:
		await arvore.physics_frame


func _instanciar_estrutura(dados: Dictionary) -> void:
	var cena_obj := load(dados.cena) as PackedScene
	if cena_obj == null:
		push_error("SaveManager: cena nao encontrada: ", dados.cena)
		return
	var pos_array: Array = dados.posicao
	var posicao := Vector2(pos_array[0], pos_array[1])
	var inst = StructureFactory.criar("", cena_obj, posicao, dados.rotacao, false)
	if inst.has_method("set_save_data") and dados.has("dados"):
		inst.set_save_data(dados.dados)
	var arvore := get_tree()
	if arvore == null or arvore.current_scene == null:
		inst.queue_free()
		return
	arvore.current_scene.add_child(inst)
