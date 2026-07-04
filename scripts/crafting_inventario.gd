class_name CraftingInventarioModule extends RefCounted

var _slots_inventario: Array = []
var _slot_swap_origem: int = -1
var _jogador: Node = null
var _util: CraftingUtil

var _grid_inventario: GridContainer


func setup(
	grid_inventario: GridContainer,
	jogador: Node,
	util: CraftingUtil
) -> void:
	_grid_inventario = grid_inventario
	_jogador = jogador
	_util = util

	_construir_slots()


func _construir_slots() -> void:
	_slots_inventario.clear()
	for filho in _grid_inventario.get_children():
		filho.queue_free()

	for i in range(9):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.size_flags_horizontal = 3
		btn.size_flags_vertical = 3

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = 3
		vbox.size_flags_vertical = 3
		btn.add_child(vbox)

		var icone_slot = TextureRect.new()
		icone_slot.custom_minimum_size = Vector2(64, 64)
		icone_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone_slot.size_flags_horizontal = 3
		vbox.add_child(icone_slot)

		var label_slot = Label.new()
		label_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_slot.add_theme_font_size_override("font_size", 12)
		label_slot.size_flags_horizontal = 3
		vbox.add_child(label_slot)

		var idx = i
		btn.pressed.connect(func(): _slot_pressed(idx))

		_grid_inventario.add_child(btn)
		_slots_inventario.append({"container": btn, "icone": icone_slot, "label": label_slot})

	atualizar_slots()


func _slot_pressed(idx: int) -> void:
	if _slot_swap_origem == -1:
		_slot_swap_origem = idx
		atualizar_slots()
		return
	if _slot_swap_origem != idx:
		var itens = _jogador.get_itens_construcao()
		var a = _slot_swap_origem
		var b = idx
		if a < itens.size() and b < itens.size():
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
		var slot_data = _slots_inventario[i]
		if i < itens.size():
			var item: ItemConstrucao = itens[i]
			slot_data.label.text = item.nome
			if item.cena_objeto:
				var temp = item.cena_objeto.instantiate()
				slot_data.icone.texture = _util.extrair_textura(temp)
				temp.queue_free()
		else:
			slot_data.label.text = "[Vazio]"
			slot_data.icone.texture = null
		var btn: Button = slot_data.container
		if _slot_swap_origem == i:
			btn.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
