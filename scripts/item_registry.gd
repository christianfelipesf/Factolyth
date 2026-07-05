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
	},
	itens = {
		quartzo       = {nome = "Quartzo",         textura = "res://images/itens/po_quartzo.png"},
		placa_quartzo = {nome = "Placa de Quartzo",textura = "res://images/itens/placa_de_quartzo.png"},
		areia         = {nome = "Areia",           textura = "res://images/itens/areia.png"},
	},
	receitas_item = [
		{nome = "Placa de Quartzo", resultado = "placa_quartzo", quantidade = 1, tempo = 3.0, ingredientes = {quartzo = 4}},
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

func _ready() -> void:
	_registrar_estruturas()
	_registrar_itens()
	_registrar_receitas()

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
