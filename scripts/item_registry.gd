extends Node

# ═══════════════════════════════════════════════════════
#  CONFIGURACÃO CENTRAL
# ═══════════════════════════════════════════════════════

const _CONFIG = {
	estruturas = {
		Broca =        {cena = "res://scenes/posicionaveis/broca.tscn",       custo = 2,  tempo = 0.5, receita = {placa_quartzo = 2}},
		Esteira =      {cena = "res://scenes/posicionaveis/esteira.tscn",     custo = 1,  tempo = 0.1, receita = {placa_quartzo = 1}},
		Nucleo =       {cena = "res://scenes/posicionaveis/nucleo.tscn",      custo = 8,  tempo = 0.5, receita = {placa_quartzo = 8}},
		Canhao =       {cena = "res://scenes/posicionaveis/simplecanon.tscn", custo = 6,  tempo = 0.5, receita = {placa_quartzo = 6}},
		Distribuidor = {cena = "res://scenes/posicionaveis/distribuidor.tscn",custo = 7,  tempo = 0.5, receita = {placa_quartzo = 7}},
		Cruzador =     {cena = "res://scenes/posicionaveis/cruzador.tscn",    custo = 10, tempo = 0.5, receita = {placa_quartzo = 10}},
		Fusor =        {cena = "res://scenes/posicionaveis/fusor.tscn",            custo = 0,  tempo = 0.5},
		ExtratorDeAreia = {cena = "res://scenes/posicionaveis/extrator_de_areia.tscn", custo = 3,  tempo = 0.5, receita = {placa_quartzo = 3}},
		FusorDeAreia = {cena = "res://scenes/posicionaveis/fusor_de_areia.tscn", custo = 5, tempo = 0.5, receita = {placa_quartzo = 5}},
		TorreDeEnergia = {cena = "res://scenes/posicionaveis/torre_de_energia.tscn", custo = 12, tempo = 1.5, receita = {placa_quartzo = 12}},
	},
	itens = {
		quartzo       = {nome = "Quartzo",         textura = "res://images/itens/po_quartzo.png"},
		placa_quartzo = {nome = "Placa de Quartzo",textura = "res://images/itens/placa_de_quartzo.png"},
		areia         = {nome = "Areia",           textura = "res://images/itens/areia.png"},
		silicio       = {nome = "Silicio",         textura = "res://images/itens/silicio.png"},
	},
	receitas_item = [
		{nome = "Placa de Quartzo", resultado = "placa_quartzo", quantidade = 1, tempo = 2.0, ingredientes = {quartzo = 4}},
	],
}

# ═══════════════════════════════════════════════════════
#  Dados gerados automaticamente
# ═══════════════════════════════════════════════════════

var estruturas: Dictionary = {}
var itens: Dictionary = {}
var receitas_item: Array = []
var receitas_estrutura: Array = []

var _cena_para_nome: Dictionary = {}
var _cena_para_receita: Dictionary = {}
var _nome_para_receita: Dictionary = {}

@export var injetar_dados_teste := true

func _ready() -> void:
	_registrar_estruturas()
	_registrar_itens()
	_registrar_receitas()
	if injetar_dados_teste:
		_injetar_dados_teste()

func _registrar_estruturas() -> void:
	for nome in _CONFIG.estruturas:
		var cfg = _CONFIG.estruturas[nome]
		var cena: PackedScene = load(cfg.cena)
		var entry = {cena = cena, custo = cfg.get("custo", 0), tempo = cfg.get("tempo", 0.0)}
		estruturas[nome] = entry
		_cena_para_nome[cena.resource_path] = nome
		if cfg.has("receita"):
			_cena_para_receita[cena.resource_path] = cfg.receita.duplicate()
			_nome_para_receita[nome] = cfg.receita.duplicate()
			var rec = RecipeEstruturaData.new()
			rec.nome = nome
			rec.cena_path = cfg.cena
			rec.ingredientes = cfg.receita.duplicate()
			receitas_estrutura.append(rec)

func _registrar_itens() -> void:
	for id in _CONFIG.itens:
		var cfg = _CONFIG.itens[id]
		var data = ItemData.new()
		data.id = id
		data.nome = cfg.nome
		data.textura = load(cfg.textura)
		itens[id] = data

func _registrar_receitas() -> void:
	for r in _CONFIG.receitas_item:
		var rec = RecipeData.new()
		rec.nome = r.nome
		rec.resultado = r.resultado
		rec.resultado_quantidade = r.get("quantidade", 1)
		rec.tempo_craft = r.get("tempo", 3.0)
		rec.ingredientes = r.ingredientes.duplicate()
		receitas_item.append(rec)

func _injetar_dados_teste() -> void:
	if receitas_item.size() >= 10:
		return

	var items_teste = {
		ferro =       "Ferro Bruto",
		lingote_ferro = "Lingote de Ferro",
		carvao =      "Carv\u00e3o",
		aco =         "A\u00e7o",
		cobre =       "Cobre Bruto",
		lingote_cobre = "Lingote de Cobre",
		ouro =        "Ouro Bruto",
		lingote_ouro =  "Lingote de Ouro",
		tijolo =      "Tijolo",
		vidro =       "Vidro",
		circuito =    "Circuito",
		parafuso =    "Parafuso",
		engrenagem =  "Engrenagem",
		bobina =      "Bobina de Cobre",
		lente =       "Lente de Quartzo",
		bastao_aco =  "Bast\u00e3o de A\u00e7o",
		mola =        "Mola",
		placa_ferro = "Placa de Ferro",
		tinta =       "Tinta de Sil\u00edcio",
		combustivel = "Combust\u00edvel",
		bateria =     "Bateria",
		motor =       "Motor Simples",
	}
	for id in items_teste:
		var data = ItemData.new()
		data.id = id
		data.nome = items_teste[id]
		itens[id] = data

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
		receitas_item.append(rec)

	print("ItemRegistry: dados de teste injetados (", receitas_item.size(), " receitas)")


func get_item(id: String) -> ItemData:
	return itens.get(id)

func get_custo(nome: String) -> int:
	var e = estruturas.get(nome)
	return e.custo if e else 0

func get_tempo_construcao(nome: String) -> float:
	var e = estruturas.get(nome)
	return e.tempo if e else 0.0

func get_receita_por_cena(caminho_cena: String) -> Dictionary:
	return _cena_para_receita.get(caminho_cena, {})

func get_nome_por_cena(caminho_cena: String) -> String:
	return _cena_para_nome.get(caminho_cena, "")

func get_receita_por_nome(nome: String) -> Dictionary:
	return _nome_para_receita.get(nome, {})
