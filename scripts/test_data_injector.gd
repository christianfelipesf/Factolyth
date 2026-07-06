extends Node

func injetar_dados_teste() -> void:
	if not ItemRegistry.itens.has("ferro"):
		_adicionar_items_teste()
	if ItemRegistry.receitas_item.size() < 3:
		_adicionar_receitas_item_teste()
	if ItemRegistry.receitas_estrutura.size() < 5:
		_adicionar_estruturas_teste()

	var jogador = get_tree().root.find_child("Jogador", true, false)
	if jogador == null:
		return

	var inventario_teste = {
		quartzo = 50, placa_quartzo = 30, areia = 40, silicio = 20,
		ferro = 20, lingote_ferro = 15, carvao = 25, aco = 10,
		cobre = 15, lingote_cobre = 12, ouro = 5, lingote_ouro = 3,
		tijolo = 30, vidro = 20, circuito = 8, parafuso = 40,
		engrenagem = 15, bobina = 12, lente = 6, bastao_aco = 10,
		mola = 20, placa_ferro = 15, tinta = 10, combustivel = 15,
		bateria = 8, motor = 4,
	}
	if jogador.has_method("set_inventario"):
		jogador.set_inventario(inventario_teste)
	elif jogador.get("inventario") != null:
		for id in inventario_teste:
			jogador.inventario[id] = inventario_teste[id]
		if jogador.has_signal("inventario_atualizado"):
			jogador.inventario_atualizado.emit(jogador.inventario)

	var estruturas_teste = [
		"Broca", "Esteira", "Nucleo", "Canhao", "Distribuidor",
		"Cruzador", "ExtratorDeAreia", "FusorDeAreia", "TorreDeEnergia",
		"Fornalha", "Furadeira", "Prensa", "Compressor", "Gerador",
		"Separador", "Refinaria", "Mineradora", "Soldadora",
	]
	for nome in estruturas_teste:
		if ItemRegistry.estruturas.has(nome):
			var entry = ItemRegistry.estruturas[nome]
			if entry and entry.cena:
				var item = ItemConstrucao.new()
				item.nome = nome
				item.cena_objeto = entry.cena
				item.tamanho_grid = Vector2i(1, 1)
				jogador.adicionar_item_construcao(item)

	jogador.selecionar_item_por_indice(0)


func _adicionar_items_teste() -> void:
	var items_teste = {
		ferro =       {nome = "Ferro Bruto"},
		lingote_ferro = {nome = "Lingote de Ferro"},
		carvao =      {nome = "Carv\u00e3o"},
		aco =         {nome = "A\u00e7o"},
		cobre =       {nome = "Cobre Bruto"},
		lingote_cobre = {nome = "Lingote de Cobre"},
		ouro =        {nome = "Ouro Bruto"},
		lingote_ouro =  {nome = "Lingote de Ouro"},
		tijolo =      {nome = "Tijolo"},
		vidro =       {nome = "Vidro"},
		circuito =    {nome = "Circuito"},
		parafuso =    {nome = "Parafuso"},
		engrenagem =  {nome = "Engrenagem"},
		bobina =      {nome = "Bobina de Cobre"},
		lente =       {nome = "Lente de Quartzo"},
		bastao_aco =  {nome = "Bast\u00e3o de A\u00e7o"},
		mola =        {nome = "Mola"},
		placa_ferro = {nome = "Placa de Ferro"},
		tinta =       {nome = "Tinta de Sil\u00edcio"},
		combustivel = {nome = "Combust\u00edvel"},
		bateria =     {nome = "Bateria"},
		motor =       {nome = "Motor Simples"},
	}
	for id in items_teste:
		var cfg = items_teste[id]
		var data = ItemData.new()
		data.id = id
		data.nome = cfg.nome
		ItemRegistry.itens[id] = data


func _adicionar_receitas_item_teste() -> void:
	var receitas = [
		{nome="Ferro Bruto",       resultado="ferro",       qtd=2, tempo=1.0, ing={quartzo=2}},
		{nome="Lingote de Ferro",  resultado="lingote_ferro", qtd=1, tempo=3.0, ing={ferro=3, carvao=1}},
		{nome="Placa de Ferro",    resultado="placa_ferro",   qtd=1, tempo=2.0, ing={lingote_ferro=2}},
		{nome="Carv\u00e3o",      resultado="carvao",       qtd=3, tempo=1.0, ing={areia=2, quartzo=1}},
		{nome="Cobre Bruto",       resultado="cobre",        qtd=2, tempo=1.0, ing={quartzo=3}},
		{nome="Lingote de Cobre",  resultado="lingote_cobre", qtd=1, tempo=2.5, ing={cobre=3, carvao=1}},
		{nome="Bobina de Cobre",   resultado="bobina",       qtd=2, tempo=2.0, ing={lingote_cobre=2}},
		{nome="Ouro Bruto",        resultado="ouro",         qtd=1, tempo=2.0, ing={quartzo=4}},
		{nome="Lingote de Ouro",   resultado="lingote_ouro",  qtd=1, tempo=4.0, ing={ouro=2, carvao=2}},
		{nome="A\u00e7o",         resultado="aco",          qtd=1, tempo=5.0, ing={lingote_ferro=2, carvao=1}},
		{nome="Bast\u00e3o de A\u00e7o", resultado="bastao_aco", qtd=2, tempo=2.0, ing={aco=1}},
		{nome="Mola",              resultado="mola",          qtd=3, tempo=1.5, ing={lingote_ferro=1}},
		{nome="Vidro",             resultado="vidro",        qtd=2, tempo=2.0, ing={areia=3, quartzo=1}},
		{nome="Tijolo",            resultado="tijolo",       qtd=4, tempo=2.0, ing={areia=2}},
		{nome="Circuito",          resultado="circuito",     qtd=1, tempo=4.0, ing={bobina=2, placa_ferro=1}},
		{nome="Parafuso",          resultado="parafuso",     qtd=6, tempo=1.0, ing={lingote_ferro=1}},
		{nome="Engrenagem",        resultado="engrenagem",   qtd=2, tempo=2.0, ing={lingote_ferro=2}},
		{nome="Lente de Quartzo",  resultado="lente",       qtd=1, tempo=2.0, ing={vidro=1, quartzo=2}},
		{nome="Combust\u00edvel", resultado="combustivel",   qtd=2, tempo=2.0, ing={areia=1, carvao=2}},
		{nome="Bateria",           resultado="bateria",      qtd=1, tempo=3.0, ing={bobina=1, lingote_ferro=1}},
		{nome="Tinta de Sil\u00edcio", resultado="tinta",    qtd=3, tempo=1.0, ing={silicio=1}},
		{nome="Motor Simples",     resultado="motor",        qtd=1, tempo=6.0, ing={bobina=2, engrenagem=2, bastao_aco=1}},
	]
	for r in receitas:
		var rec = RecipeData.new()
		rec.nome = r.nome
		rec.resultado = r.resultado
		rec.resultado_quantidade = r.get("qtd", 1)
		rec.tempo_craft = r.get("tempo", 3.0)
		rec.ingredientes = r.ing.duplicate()
		ItemRegistry.receitas_item.append(rec)


func _adicionar_estruturas_teste() -> void:
	var estruturas = [
		{nome="Fornalha",        cena="res://scenes/posicionaveis/fornalha.tscn",       custo=5,  tempo=0.5, ing={tijolo=10, placa_ferro=4}},
		{nome="Furadeira",       cena="res://scenes/posicionaveis/furadeira.tscn",      custo=4,  tempo=0.5, ing={engrenagem=3, bastao_aco=2}},
		{nome="Prensa",          cena="res://scenes/posicionaveis/prensa.tscn",         custo=6,  tempo=0.8, ing={lingote_ferro=4, parafuso=6}},
		{nome="Compressor",      cena="res://scenes/posicionaveis/compressor.tscn",     custo=7,  tempo=0.5, ing={placa_ferro=3, motor=1}},
		{nome="Moedor",          cena="res://scenes/posicionaveis/moedor.tscn",         custo=3,  tempo=0.3, ing={engrenagem=2, placa_ferro=2}},
		{nome="Gerador",         cena="res://scenes/posicionaveis/gerador.tscn",        custo=10, tempo=1.0, ing={motor=2, bateria=2, aco=3}},
		{nome="Separador",       cena="res://scenes/posicionaveis/separador.tscn",      custo=6,  tempo=0.5, ing={circuito=2, placa_ferro=3}},
		{nome="Refinaria",       cena="res://scenes/posicionaveis/refinaria.tscn",      custo=8,  tempo=1.0, ing={tijolo=8, lingote_cobre=4}},
		{nome="SerraEletrica",   cena="res://scenes/posicionaveis/serra_eletrica.tscn", custo=5,  tempo=0.5, ing={bastao_aco=2, motor=1, engrenagem=2}},
		{nome="Torno",           cena="res://scenes/posicionaveis/torno.tscn",          custo=6,  tempo=0.5, ing={lingote_ferro=5, parafuso=4}},
		{nome="Caldeira",        cena="res://scenes/posicionaveis/caldeira.tscn",       custo=7,  tempo=0.8, ing={placa_ferro=5, tijolo=6}},
		{nome="Transformador",   cena="res://scenes/posicionaveis/transformador.tscn",  custo=9,  tempo=1.0, ing={bobina=4, aco=2, placa_ferro=3}},
		{nome="Soldadora",       cena="res://scenes/posicionaveis/soldadora.tscn",      custo=5,  tempo=0.5, ing={lingote_cobre=3, placa_ferro=2}},
		{nome="Mineradora",      cena="res://scenes/posicionaveis/mineradora.tscn",     custo=12, tempo=1.5, ing={motor=2, aco=4, engrenagem=4}},
	]
	for e in estruturas:
		var cena = load(e.cena)
		if cena == null:
			continue
		var entry = {cena = cena, custo = e.custo, tempo = e.get("tempo", 0.5)}
		ItemRegistry.estruturas[e.nome] = entry

		var rec = RecipeEstruturaData.new()
		rec.nome = e.nome
		rec.cena_path = e.cena
		rec.ingredientes = e.ing.duplicate()
		ItemRegistry.receitas_estrutura.append(rec)
