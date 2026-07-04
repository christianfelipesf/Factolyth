extends Control

const RECEITAS = [
	preload("res://resources/recipes/placa_quartzo.tres"),
]

var _craftando := false
var _receita_atual: RecipeData = null
var _tempo_restante := 0.0
var _jogador: Node = null
var _botoes_receita: Array = []

@onready var fundo: ColorRect = $Fundo
@onready var painel: Panel = $Painel
@onready var vbox_receitas: VBoxContainer = $Painel/VBox/Meio/Lista/VBoxReceitas
@onready var icone: TextureRect = $Painel/VBox/Meio/Detalhes/VBoxDetalhes/Icone
@onready var nome_label: Label = $Painel/VBox/Meio/Detalhes/VBoxDetalhes/Nome
@onready var container_ingredientes: VBoxContainer = $Painel/VBox/Meio/Detalhes/VBoxDetalhes/ContainerIngredientes
@onready var progresso: ProgressBar = $Painel/VBox/Meio/Detalhes/VBoxDetalhes/Progresso
@onready var tempo_label: Label = $Painel/VBox/Meio/Detalhes/VBoxDetalhes/TempoLabel
@onready var botao: Button = $Painel/VBox/Meio/Detalhes/VBoxDetalhes/Botao
@onready var fechar: Button = $Painel/VBox/Topo/Fechar

func _ready() -> void:
	hide()
	progresso.hide()
	tempo_label.hide()
	progresso.max_value = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jogador = get_node("/root/Mundo/Jogador")
	if _jogador == null:
		printerr("CraftingHUD: jogador não encontrado")
		return
	
	fundo.gui_input.connect(_on_fundo_clique)
	fechar.pressed.connect(_fechar)
	botao.pressed.connect(_iniciar_craft)
	_jogador.inventario_atualizado.connect(_ao_atualizar_inventario)
	_construir_lista()

func _construir_lista() -> void:
	for i in RECEITAS.size():
		var receita = RECEITAS[i]
		var btn = Button.new()
		btn.text = receita.nome
		btn.custom_minimum_size = Vector2(0, 28)
		btn.size_flags_horizontal = 3
		var idx = i
		btn.pressed.connect(func(): _selecionar_receita(idx))
		vbox_receitas.add_child(btn)
		_botoes_receita.append(btn)
	
	if not RECEITAS.is_empty():
		_selecionar_receita(0)

func _ao_atualizar_inventario(_inv: Dictionary) -> void:
	if visible:
		_atualizar_detalhes()

func _selecionar_receita(idx: int) -> void:
	_receita_atual = RECEITAS[idx]
	_atualizar_detalhes()

func _atualizar_detalhes() -> void:
	if _receita_atual == null:
		return
	
	var dados = ItemDB.get_item(_receita_atual.resultado)
	if dados and dados.textura:
		icone.texture = dados.textura
	nome_label.text = str(_receita_atual.resultado_quantidade) + "x " + _receita_atual.nome
	
	for child in container_ingredientes.get_children():
		child.queue_free()
	
	for ing in _receita_atual.ingredientes:
		var quant = _receita_atual.ingredientes[ing]
		var dados_ing = ItemDB.get_item(ing)
		var nome_ing = dados_ing.nome if dados_ing else ing
		var tem = _jogador.inventario.get(ing, 0)
		
		var linha = HBoxContainer.new()
		linha.size_flags_horizontal = 3
		
		var icone_ing = TextureRect.new()
		icone_ing.custom_minimum_size = Vector2(24, 24)
		icone_ing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if dados_ing and dados_ing.textura:
			icone_ing.texture = dados_ing.textura
		linha.add_child(icone_ing)
		
		var label = Label.new()
		label.text = nome_ing + ": " + str(tem) + "/" + str(quant)
		label.add_theme_color_override("font_color", Color(0.27, 1.0, 0.27) if tem >= quant else Color(1.0, 0.27, 0.27))
		label.add_theme_font_size_override("font_size", 13)
		linha.add_child(label)
		
		container_ingredientes.add_child(linha)
	
	botao.disabled = not _pode_craftar()
	progresso.hide()

func _process(delta: float) -> void:
	if _craftando:
		_tempo_restante -= delta
		var prog = 1.0 - (_tempo_restante / _receita_atual.tempo_craft)
		progresso.value = prog
		tempo_label.text = str(snapped(_tempo_restante, 0.1)) + "s"
		if _tempo_restante <= 0:
			_finalizar_craft()

func toggle() -> void:
	if _craftando:
		return
	if visible:
		_fechar()
	else:
		_abrir()

func _abrir() -> void:
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_atualizar_detalhes()

func _fechar() -> void:
	if _craftando:
		return
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_fundo_clique(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fechar()

func _pode_craftar() -> bool:
	if _receita_atual == null:
		return false
	for ing in _receita_atual.ingredientes:
		if _jogador.inventario.get(ing, 0) < _receita_atual.ingredientes[ing]:
			return false
	return true

func _iniciar_craft() -> void:
	if not _pode_craftar():
		return
	for ing in _receita_atual.ingredientes:
		_jogador.inventario[ing] -= _receita_atual.ingredientes[ing]
	_jogador.inventario_atualizado.emit(_jogador.inventario)
	_craftando = true
	_tempo_restante = _receita_atual.tempo_craft
	progresso.show()
	tempo_label.show()
	progresso.value = 0.0
	tempo_label.text = str(_receita_atual.tempo_craft) + "s"
	botao.hide()

func _finalizar_craft() -> void:
	_craftando = false
	_jogador.adicionar_item(_receita_atual.resultado, _receita_atual.resultado_quantidade)
	progresso.hide()
	tempo_label.hide()
	botao.show()
	_atualizar_detalhes()
