extends Node2D

func _ready() -> void:
	_popular_inventario()

func _popular_inventario() -> void:
	var jogador = get_tree().root.find_child("Jogador", true, false)
	if jogador == null:
		return

	var inv = {
		quartzo = 80, placa_quartzo = 30, areia = 80, silicio = 40,
		ferro = 60, lingote_ferro = 30, carvao = 50, aco = 20,
		cobre = 40, lingote_cobre = 25, ouro = 15, lingote_ouro = 10,
		tijolo = 60, vidro = 40, circuito = 20, parafuso = 80,
		engrenagem = 30, bobina = 25, lente = 12, bastao_aco = 20,
		mola = 40, placa_ferro = 30, tinta = 20, combustivel = 30,
		bateria = 16, motor = 8,
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
