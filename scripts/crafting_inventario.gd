class_name CraftingInventarioModule extends RefCounted

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


func atualizar_inventario_player() -> void:
	if _grid_inventario == null or _jogador == null:
		return

	for filho in _grid_inventario.get_children():
		filho.queue_free()

	var ids = _jogador.inventario.keys()
	ids.sort()
	for id in ids:
		var quant = _jogador.inventario[id]
		if quant <= 0:
			continue

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.size_flags_horizontal = 3
		btn.size_flags_vertical = 3

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = 4
		vbox.size_flags_vertical = 4
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn.add_child(vbox)

		var icone = TextureRect.new()
		icone.custom_minimum_size = Vector2(40, 40)
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.size_flags_horizontal = 4
		var dados = ItemRegistry.get_item(id)
		if dados and dados.textura:
			icone.texture = dados.textura
		vbox.add_child(icone)

		var label = Label.new()
		var nome = dados.nome if dados else id
		label.text = nome + "\n" + str(quant) + "x"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.size_flags_horizontal = 4
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		vbox.add_child(label)

		_grid_inventario.add_child(btn)
