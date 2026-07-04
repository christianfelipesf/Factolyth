class_name CraftingItemModule extends RefCounted

var _craftando := false
var _receita_atual: RecipeData = null
var _tempo_restante := 0.0
var _jogador: Node = null
var _botoes_receita: Array = []
var _util: CraftingUtil

var _icone: TextureRect
var _nome_label: Label
var _container_ingredientes: VBoxContainer
var _progresso: ProgressBar
var _tempo_label: Label
var _botao: Button
var _vbox_receitas: VBoxContainer


func setup(
	icone: TextureRect,
	nome_label: Label,
	container_ingredientes: VBoxContainer,
	progresso: ProgressBar,
	tempo_label: Label,
	botao: Button,
	vbox_receitas: VBoxContainer,
	jogador: Node,
	util: CraftingUtil
) -> void:
	_icone = icone
	_nome_label = nome_label
	_container_ingredientes = container_ingredientes
	_progresso = progresso
	_tempo_label = tempo_label
	_botao = botao
	_vbox_receitas = vbox_receitas
	_jogador = jogador
	_util = util

	_progresso.max_value = 1.0
	_progresso.hide()
	_tempo_label.hide()

	_construir_lista_itens()


func _construir_lista_itens() -> void:
	var receitas = ItemRegistry.receitas_item
	for i in receitas.size():
		var receita = receitas[i]
		var btn = Button.new()
		btn.text = receita.nome
		btn.custom_minimum_size = Vector2(0, 28)
		btn.size_flags_horizontal = 3
		var idx = i
		btn.pressed.connect(func(): _selecionar_receita(idx))
		_vbox_receitas.add_child(btn)
		_botoes_receita.append(btn)

	if not ItemRegistry.receitas_item.is_empty():
		_selecionar_receita(0)


func _selecionar_receita(idx: int) -> void:
	_receita_atual = ItemRegistry.receitas_item[idx]
	atualizar_detalhes()


func atualizar_detalhes() -> void:
	if _receita_atual == null:
		return

	var dados = ItemRegistry.get_item(_receita_atual.resultado)
	if dados and dados.textura:
		_icone.texture = dados.textura
	_nome_label.text = str(_receita_atual.resultado_quantidade) + "x " + _receita_atual.nome

	for child in _container_ingredientes.get_children():
		child.queue_free()

	for ing in _receita_atual.ingredientes:
		var quant = _receita_atual.ingredientes[ing]
		var dados_ing = ItemRegistry.get_item(ing)
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

		_container_ingredientes.add_child(linha)

	_botao.disabled = not _pode_craftar()
	_progresso.hide()


func process(delta: float) -> void:
	if _craftando:
		_tempo_restante -= delta
		var prog = 1.0 - (_tempo_restante / _receita_atual.tempo_craft)
		_progresso.value = prog
		_tempo_label.text = str(snapped(_tempo_restante, 0.1)) + "s"
		if _tempo_restante <= 0:
			_finalizar_craft()


func esta_craftando() -> bool:
	return _craftando


func _pode_craftar() -> bool:
	if _receita_atual == null:
		return false
	for ing in _receita_atual.ingredientes:
		if _jogador.inventario.get(ing, 0) < _receita_atual.ingredientes[ing]:
			return false
	return true


func iniciar_craft() -> void:
	if not _pode_craftar():
		return
	for ing in _receita_atual.ingredientes:
		_jogador.inventario[ing] -= _receita_atual.ingredientes[ing]
	_jogador.inventario_atualizado.emit(_jogador.inventario)
	_craftando = true
	_tempo_restante = _receita_atual.tempo_craft
	_progresso.show()
	_tempo_label.show()
	_progresso.value = 0.0
	_tempo_label.text = str(_receita_atual.tempo_craft) + "s"
	_botao.hide()


func _finalizar_craft() -> void:
	_craftando = false
	_jogador.adicionar_item(_receita_atual.resultado, _receita_atual.resultado_quantidade)
	_progresso.hide()
	_tempo_label.hide()
	_botao.show()
	atualizar_detalhes()
