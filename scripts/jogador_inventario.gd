class_name JogadorInventarioModule extends RefCounted

const BROCA_MANUAL_CENA = preload("res://scenes/posicionaveis/broca_manual.tscn")

var _jogador: Node


func setup(jogador: Node) -> void:
	_jogador = jogador


func carregar_itens_construcao() -> void:
	var lista = ItemRegistry.estruturas.duplicate()
	if SaveManager.modo_jogo == "sobrevivencia":
		lista = {"BrocaManual": {cena = BROCA_MANUAL_CENA}}
	for nome in lista:
		_adicionar_item_com_cena(nome, lista[nome].cena)
	if _jogador._itens_construcao.is_empty():
		push_error("Nenhum item construível encontrado")


func _adicionar_item_com_cena(nome: String, cena: PackedScene) -> void:
	var item = ItemConstrucao.new()
	item.nome = nome
	item.cena_objeto = cena
	item.compensar_rotacao_90 = false
	item.tamanho_grid = _extrair_tamanho_grid(cena)
	_jogador._itens_construcao.append(item)


func adicionar_item(tipo_id: String, quantidade: int = 1) -> void:
	if _jogador.inventario.has(tipo_id):
		_jogador.inventario[tipo_id] += quantidade
	else:
		_jogador.inventario[tipo_id] = quantidade
	_jogador.inventario_atualizado.emit(_jogador.inventario)


func adicionar_item_construcao(item: ItemConstrucao) -> void:
	_jogador._itens_construcao.append(item)
	_jogador.itens_construcao_atualizados.emit()


func _extrair_tamanho_grid(cena: PackedScene) -> Vector2i:
	var inst = cena.instantiate()
	if inst == null:
		return Vector2i(1, 1)
	var val = inst.get("TAMANHO_GRID")
	inst.free()
	return val if val != null else Vector2i(1, 1)
