extends Node2D

func _ready() -> void:
	if SaveManager.modo_jogo == SaveManager.MODO_CRIATIVO:
		_popular_inventario()

func _popular_inventario() -> void:
	var jogador = get_tree().root.find_child("Jogador", true, false)
	if jogador == null:
		return

	var inv = {
		quartzo = 80, placa_quartzo = 30, areia = 80, silicio = 40,
	}
	for id in inv:
		jogador.inventario[id] = inv[id]
	if jogador.has_signal("inventario_atualizado"):
		jogador.inventario_atualizado.emit(jogador.inventario)

	var estruturas = ["Broca", "Esteira", "Nucleo", "Canhao", "Distribuidor",
		"Cruzador", "ExtratorDeAreia", "FusorDeAreia", "TorreDeEnergia"]
	for nome in estruturas:
		if ItemRegistry.estruturas.has(nome):
			var entry = ItemRegistry.estruturas[nome]
			if entry and entry.cena:
				var item = ItemConstrucao.new()
				item.nome = nome
				item.cena_objeto = entry.cena
				item.tamanho_grid = Vector2i(1, 1)
				jogador.adicionar_item_construcao(item)

	jogador.selecionar_item_por_indice(0)
