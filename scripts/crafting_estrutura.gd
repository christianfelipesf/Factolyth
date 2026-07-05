class_name CraftingEstruturaModule extends RefCounted

var _receita_estrutura_selecionada: int = -1
var _botoes_receita_estrutura: Array = []
var _slots_estrutura: Array = []
var _slot_swap_origem: int = -1
var _jogador: Node = null
var _util: CraftingUtil

var _grid_slots: GridContainer
var _vbox_receitas_estrutura: VBoxContainer
var _btn_fabricar: Button

var _eh_criativo: bool
var _nomes_estrutura: Array[String] = []


func setup(
	grid_slots: GridContainer,
	vbox_receitas_estrutura: VBoxContainer,
	btn_fabricar: Button,
	jogador: Node,
	util: CraftingUtil
) -> void:
	_grid_slots = grid_slots
	_vbox_receitas_estrutura = vbox_receitas_estrutura
	_btn_fabricar = btn_fabricar
	_jogador = jogador
	_util = util
	_eh_criativo = SaveManager.modo_jogo == "criativo"

	_construir_slots()
	if _eh_criativo:
		_construir_lista_criativo()
	else:
		_construir_lista_estruturas()


func _construir_slots() -> void:
	_slots_estrutura.clear()
	for filho in _grid_slots.get_children():
		filho.queue_free()

	for i in range(9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(90, 90)
		btn.size_flags_horizontal = 3
		btn.size_flags_vertical = 3

		var icone_slot = TextureRect.new()
		icone_slot.custom_minimum_size = Vector2(48, 48)
		icone_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		btn.add_child(icone_slot)

		var label_slot = Label.new()
		label_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_slot.add_theme_font_size_override("font_size", 11)
		btn.add_child(label_slot)

		var idx = i
		btn.pressed.connect(func(): _slot_pressed(idx))

		_grid_slots.add_child(btn)
		_slots_estrutura.append({"container": btn, "icone": icone_slot, "label": label_slot})

	atualizar_slots()


func _construir_lista_estruturas() -> void:
	var receitas = ItemRegistry.receitas_estrutura
	for i in receitas.size():
		var receita = receitas[i]
		var btn = Button.new()
		btn.text = receita.nome
		btn.custom_minimum_size = Vector2(0, 28)
		btn.size_flags_horizontal = 3
		var idx = i
		btn.pressed.connect(func(): _selecionar_receita(idx))
		_vbox_receitas_estrutura.add_child(btn)
		_botoes_receita_estrutura.append(btn)

	if not ItemRegistry.receitas_estrutura.is_empty():
		_selecionar_receita(0)


func _construir_lista_criativo() -> void:
	_nomes_estrutura.clear()
	for nome in ItemRegistry.estruturas:
		_nomes_estrutura.append(nome)
	_nomes_estrutura.sort()

	for filho in _vbox_receitas_estrutura.get_children():
		filho.queue_free()

	var grid = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = 3
	grid.size_flags_vertical = 3
	_vbox_receitas_estrutura.add_child(grid)

	for nome in _nomes_estrutura:
		var entry = ItemRegistry.estruturas.get(nome)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 90)
		btn.size_flags_horizontal = 3
		btn.size_flags_vertical = 3
		btn.toggle_mode = true
		btn.pressed.connect(_toggle_estrutura.bind(nome))

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = 4
		vbox.size_flags_vertical = 4
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn.add_child(vbox)

		var icone = TextureRect.new()
		icone.custom_minimum_size = Vector2(48, 48)
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.size_flags_horizontal = 4
		if entry and entry.cena:
			var temp = entry.cena.instantiate()
			icone.texture = _util.extrair_textura(temp)
			temp.queue_free()
		vbox.add_child(icone)

		var label = Label.new()
		label.text = nome
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = 4
		vbox.add_child(label)

		grid.add_child(btn)
		_botoes_receita_estrutura.append(btn)

	atualizar_botoes()


func _toggle_estrutura(nome: String) -> void:
	if _jogador == null:
		return
	var ja_tem = false
	for item in _jogador.get_itens_construcao():
		if item.nome == nome:
			ja_tem = true
			break
	if ja_tem:
		_jogador.remover_item_construcao(nome)
	else:
		var entry = ItemRegistry.estruturas.get(nome)
		if entry == null:
			return
		var novo_item = ItemConstrucao.new()
		novo_item.nome = nome
		novo_item.cena_objeto = entry.cena
		novo_item.compensar_rotacao_90 = false
		novo_item.tamanho_grid = _util.extrair_tamanho_grid(entry.cena)
		_jogador.adicionar_item_construcao(novo_item)


func _selecionar_receita(idx: int) -> void:
	_receita_estrutura_selecionada = idx
	atualizar_botoes()


func _slot_pressed(idx: int) -> void:
	if _jogador == null:
		return
	var itens = _jogador.get_itens_construcao()
	if idx >= itens.size():
		_slot_swap_origem = -1
		atualizar_slots()
		return
	if _eh_criativo:
		_jogador.remover_item_construcao(itens[idx].nome)
		_slot_swap_origem = -1
		atualizar_slots()
		return
	if _slot_swap_origem == -1:
		_slot_swap_origem = idx
		atualizar_slots()
		return
	if _slot_swap_origem != idx and _slot_swap_origem < itens.size() and idx < itens.size():
		var a = _slot_swap_origem
		var b = idx
		var temp = itens[a]
		itens[a] = itens[b]
		itens[b] = temp
		_jogador.selecionar_item_por_indice(b)
		_jogador.itens_construcao_atualizados.emit()
	_slot_swap_origem = -1
	atualizar_slots()


func atualizar_slots() -> void:
	if _jogador == null:
		return
	var itens = _jogador.get_itens_construcao()
	for i in range(9):
		var slot_data = _slots_estrutura[i]
		if i < itens.size():
			var item: ItemConstrucao = itens[i]
			slot_data.label.text = item.nome
			if item.cena_objeto:
				var temp = item.cena_objeto.instantiate()
				slot_data.icone.texture = _util.extrair_textura(temp)
				temp.queue_free()
			else:
				slot_data.icone.texture = null
		else:
			slot_data.label.text = "[Vazio]" if not _eh_criativo else ""
			slot_data.icone.texture = null
		var btn: Button = slot_data.container
		if _slot_swap_origem == i:
			btn.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))

	if _eh_criativo:
		atualizar_botoes()


func atualizar_botoes() -> void:
	if _jogador == null:
		return
	if _eh_criativo:
		_btn_fabricar.hide()
		var itens = _jogador.get_itens_construcao()
		for i in _botoes_receita_estrutura.size():
			var btn = _botoes_receita_estrutura[i]
			var nome = _nomes_estrutura[i] if i < _nomes_estrutura.size() else ""
			var na_barra = false
			for item in itens:
				if item.nome == nome:
					na_barra = true
					break
			btn.button_pressed = na_barra
			if na_barra:
				btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			else:
				btn.add_theme_color_override("font_color", Color(1, 1, 1))
		return

	var pode_fabricar = _pode_fabricar_estrutura()
	_btn_fabricar.disabled = not pode_fabricar
	_btn_fabricar.show()

	var receitas = ItemRegistry.receitas_estrutura
	for i in _botoes_receita_estrutura.size():
		var btn = _botoes_receita_estrutura[i]
		var rec = receitas[i]
		var textos: Array = []
		for ing in rec.ingredientes:
			var quant = rec.ingredientes[ing]
			var tem = _jogador.inventario.get(ing, 0)
			textos.append(ing + " " + str(tem) + "/" + str(quant))
		btn.text = rec.nome + "  (" + ", ".join(textos) + ")"

		if i == _receita_estrutura_selecionada:
			btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))


func _pode_fabricar_estrutura() -> bool:
	var receitas = ItemRegistry.receitas_estrutura
	if _receita_estrutura_selecionada < 0 or _receita_estrutura_selecionada >= receitas.size():
		return false
	var rec = receitas[_receita_estrutura_selecionada]
	for ing in rec.ingredientes:
		if _jogador.inventario.get(ing, 0) < rec.ingredientes[ing]:
			return false
	return true


func fabricar_estrutura() -> void:
	if not _pode_fabricar_estrutura():
		return
	if _jogador == null:
		return

	var rec = ItemRegistry.receitas_estrutura[_receita_estrutura_selecionada]

	for ing in rec.ingredientes:
		_jogador.inventario[ing] -= rec.ingredientes[ing]
	_jogador.inventario_atualizado.emit(_jogador.inventario)

	var cena_obj: PackedScene = load(rec.cena_path)
	if cena_obj == null:
		push_error("CraftingEstrutura: cena nao encontrada: ", rec.cena_path)
		return

	var novo_item = ItemConstrucao.new()
	novo_item.nome = rec.nome
	novo_item.cena_objeto = cena_obj
	novo_item.compensar_rotacao_90 = false
	novo_item.tamanho_grid = _util.extrair_tamanho_grid(cena_obj)

	_jogador.adicionar_item_construcao(novo_item)
