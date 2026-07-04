class_name JogadorInventarioModule extends RefCounted

const _BROCA = preload("res://scenes/posicionaveis/broca.tscn")
const _ESTEIRA = preload("res://scenes/posicionaveis/esteira.tscn")
const _NUCLEO = preload("res://scenes/posicionaveis/nucleo.tscn")
const _CANHAO = preload("res://scenes/posicionaveis/simplecanon.tscn")
const _DISTRIBUIDOR = preload("res://scenes/posicionaveis/distribuidor.tscn")
const _CRUZADOR = preload("res://scenes/posicionaveis/cruzador.tscn")
const _BROCA_MANUAL = preload("res://scenes/posicionaveis/broca_manual.tscn")

var _jogador: Node


func setup(jogador: Node) -> void:
	_jogador = jogador


func carregar_itens_construcao() -> void:
	if SaveManager.modo_jogo == "sobrevivencia":
		_adicionar_item_com_cena("BrocaManual", _BROCA_MANUAL)
	else:
		_adicionar_item_com_cena("Broca", _BROCA)
		_adicionar_item_com_cena("Esteira", _ESTEIRA)
		_adicionar_item_com_cena("Nucleo", _NUCLEO)
		_adicionar_item_com_cena("Canhao", _CANHAO)
		_adicionar_item_com_cena("Distribuidor", _DISTRIBUIDOR)
		_adicionar_item_com_cena("Cruzador", _CRUZADOR)
		_adicionar_item_com_cena("BrocaManual", _BROCA_MANUAL)
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
