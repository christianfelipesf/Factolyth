extends Control

# --- Receitas de Itens (existente) ---
const RECEITAS = [
	preload("res://resources/recipes/placa_quartzo.tres"),
]

# --- Receitas de Estruturas ---
const RECEITAS_ESTRUTURA = [
	preload("res://resources/recipes_estrutura/broca.tres"),
	preload("res://resources/recipes_estrutura/esteira.tres"),
	preload("res://resources/recipes_estrutura/nucleo.tres"),
	preload("res://resources/recipes_estrutura/canhao.tres"),
	preload("res://resources/recipes_estrutura/distribuidor.tres"),
	preload("res://resources/recipes_estrutura/cruzador.tres"),
]

# --- Estado do Craft de Itens (existente) ---
var _craftando := false
var _receita_atual: RecipeData = null
var _tempo_restante := 0.0
var _jogador: Node = null
var _botoes_receita: Array = []

# --- Estado da Aba Estruturas ---
var _aba_atual: String = "itens"  # "itens" ou "estruturas"
var _receita_estrutura_selecionada: int = -1
var _botoes_receita_estrutura: Array = []
var _slots_estrutura: Array = []  # 9 slots, cada um Label ou Control
var _slot_swap_origem: int = -1  # para trocar ordem dos slots
var _slots_inventario: Array = []

# --- Referências dos nós (existente adaptado) ---
@onready var fundo: ColorRect = $Fundo
@onready var painel: Panel = $Painel
@onready var vbox: VBoxContainer = $Painel/VBox

# Abas
@onready var btn_itens: Button = $Painel/VBox/Abas/BtnItens
@onready var btn_estruturas: Button = $Painel/VBox/Abas/BtnEstruturas
@onready var btn_inventario: Button = $Painel/VBox/Abas/BtnInventario

# Conteúdo Itens (caminhos relativos atualizados)
@onready var conteudo_itens: VBoxContainer = $Painel/VBox/ConteudoItens
@onready var conteudo_inventario: VBoxContainer = $Painel/VBox/ConteudoInventario
@onready var grid_inventario: GridContainer = $Painel/VBox/ConteudoInventario/GridInventario
@onready var vbox_receitas: VBoxContainer = $Painel/VBox/ConteudoItens/Meio/Lista/VBoxReceitas
@onready var icone: TextureRect = $Painel/VBox/ConteudoItens/Meio/Detalhes/VBoxDetalhes/Icone
@onready var nome_label: Label = $Painel/VBox/ConteudoItens/Meio/Detalhes/VBoxDetalhes/Nome
@onready var container_ingredientes: VBoxContainer = $Painel/VBox/ConteudoItens/Meio/Detalhes/VBoxDetalhes/ContainerIngredientes
@onready var progresso: ProgressBar = $Painel/VBox/ConteudoItens/Meio/Detalhes/VBoxDetalhes/Progresso
@onready var tempo_label: Label = $Painel/VBox/ConteudoItens/Meio/Detalhes/VBoxDetalhes/TempoLabel
@onready var botao: Button = $Painel/VBox/ConteudoItens/Meio/Detalhes/VBoxDetalhes/Botao
@onready var fechar: Button = $Painel/VBox/Topo/Fechar

# Conteúdo Estruturas
@onready var conteudo_estruturas: VBoxContainer = $Painel/VBox/ConteudoEstruturas
@onready var grid_slots: GridContainer = $Painel/VBox/ConteudoEstruturas/GridSlots
@onready var scroll_estruturas: ScrollContainer = $Painel/VBox/ConteudoEstruturas/ScrollEstruturas
@onready var vbox_receitas_estrutura: VBoxContainer = $Painel/VBox/ConteudoEstruturas/ScrollEstruturas/VBoxReceitasEstrutura
@onready var btn_fabricar: Button = $Painel/VBox/ConteudoEstruturas/Fabricar


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
	btn_fabricar.pressed.connect(_fabricar_estrutura)
	btn_itens.pressed.connect(func(): _alternar_aba("itens"))
	btn_estruturas.pressed.connect(func(): _alternar_aba("estruturas"))
	btn_inventario.pressed.connect(func(): _alternar_aba("inventario"))
	_jogador.inventario_atualizado.connect(_ao_atualizar_inventario)
	_jogador.item_selecionado.connect(_ao_atualizar_slots)
	_jogador.itens_construcao_atualizados.connect(_ao_atualizar_slots_estruturas)

	_construir_lista_itens()
	_construir_lista_estruturas()
	_construir_slots_estruturas()
	_construir_slots_inventario()
	_alternar_aba("itens")


# ---------------------------------------------------------------------------
# Abas
# ---------------------------------------------------------------------------
func _alternar_aba(aba: String) -> void:
	_aba_atual = aba
	conteudo_itens.visible = (aba == "itens")
	conteudo_estruturas.visible = (aba == "estruturas")
	conteudo_inventario.visible = (aba == "inventario")
	btn_itens.disabled = (aba == "itens")
	btn_estruturas.disabled = (aba == "estruturas")
	btn_inventario.disabled = (aba == "inventario")
	if aba in ["estruturas", "inventario"]:
		_atualizar_slots_estruturas()
		if aba == "inventario":
			_atualizar_slots_inventario()


# ---------------------------------------------------------------------------
# Lista de receitas de Itens (existente)
# ---------------------------------------------------------------------------
func _construir_lista_itens() -> void:
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
		if _aba_atual == "estruturas":
			_atualizar_botoes_estruturas()


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
	_atualizar_slots_estruturas()
	_atualizar_botoes_estruturas()


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


# ---------------------------------------------------------------------------
# Aba Estruturas - Slots 3x3
# ---------------------------------------------------------------------------
func _construir_slots_estruturas() -> void:
	_slots_estrutura.clear()
	for filho in grid_slots.get_children():
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
		btn.pressed.connect(func(): _slot_estrutura_pressed(idx))

		grid_slots.add_child(btn)
		_slots_estrutura.append({"container": btn, "icone": icone_slot, "label": label_slot})

	_atualizar_slots_estruturas()


func _ao_atualizar_slots(_indice: int) -> void:
	if not visible:
		return
	_atualizar_slots_estruturas()
	_atualizar_slots_inventario()

func _ao_atualizar_slots_estruturas() -> void:
	if not visible:
		return
	_atualizar_slots_estruturas()
	_atualizar_botoes_estruturas()
	_atualizar_slots_inventario()


func _slot_estrutura_pressed(idx: int) -> void:
	if _jogador == null:
		return
	var itens = _jogador.get_itens_construcao()
	if idx >= itens.size():
		_slot_swap_origem = -1
		_atualizar_slots_estruturas()
		return
	if _slot_swap_origem == -1:
		_slot_swap_origem = idx
		_atualizar_slots_estruturas()
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
	_atualizar_slots_estruturas()

func _atualizar_slots_estruturas() -> void:
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
				slot_data.icone.texture = _extrair_textura(temp)
				temp.queue_free()
			else:
				slot_data.icone.texture = null
		else:
			slot_data.label.text = "[Vazio]"
			slot_data.icone.texture = null
		# destaque visual para swap
		var btn: Button = slot_data.container
		if _slot_swap_origem == i:
			btn.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))


# ---------------------------------------------------------------------------
# Aba Inventário - Slots grandes para reorganizar
# ---------------------------------------------------------------------------
func _construir_slots_inventario() -> void:
	_slots_inventario.clear()
	for filho in grid_inventario.get_children():
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
		btn.pressed.connect(func():
			if _slot_swap_origem == -1:
				_slot_swap_origem = idx
			elif _slot_swap_origem != idx:
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
			_atualizar_slots_inventario()
		)

		grid_inventario.add_child(btn)
		_slots_inventario.append({"container": btn, "icone": icone_slot, "label": label_slot})

	_atualizar_slots_inventario()

func _atualizar_slots_inventario() -> void:
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
				slot_data.icone.texture = _extrair_textura(temp)
				temp.queue_free()
		else:
			slot_data.label.text = "[Vazio]"
			slot_data.icone.texture = null
		var btn: Button = slot_data.container
		if _slot_swap_origem == i:
			btn.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color(1, 1, 1))


# ---------------------------------------------------------------------------
# Aba Estruturas - Lista de Receitas
# ---------------------------------------------------------------------------
func _construir_lista_estruturas() -> void:
	for i in RECEITAS_ESTRUTURA.size():
		var receita = RECEITAS_ESTRUTURA[i]
		var btn = Button.new()
		btn.text = receita.nome
		btn.custom_minimum_size = Vector2(0, 28)
		btn.size_flags_horizontal = 3
		var idx = i
		btn.pressed.connect(func(): _selecionar_receita_estrutura(idx))
		vbox_receitas_estrutura.add_child(btn)
		_botoes_receita_estrutura.append(btn)

	if not RECEITAS_ESTRUTURA.is_empty():
		_selecionar_receita_estrutura(0)


func _selecionar_receita_estrutura(idx: int) -> void:
	_receita_estrutura_selecionada = idx
	_atualizar_botoes_estruturas()


func _atualizar_botoes_estruturas() -> void:
	if _jogador == null:
		return
	var pode_fabricar = _pode_fabricar_estrutura()
	btn_fabricar.disabled = not pode_fabricar

	for i in _botoes_receita_estrutura.size():
		var btn = _botoes_receita_estrutura[i]
		var rec = RECEITAS_ESTRUTURA[i]
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
	if _receita_estrutura_selecionada < 0 or _receita_estrutura_selecionada >= RECEITAS_ESTRUTURA.size():
		return false
	var rec = RECEITAS_ESTRUTURA[_receita_estrutura_selecionada]
	for ing in rec.ingredientes:
		if _jogador.inventario.get(ing, 0) < rec.ingredientes[ing]:
			return false
	return true


func _fabricar_estrutura() -> void:
	if not _pode_fabricar_estrutura():
		return
	if _jogador == null:
		return

	var rec = RECEITAS_ESTRUTURA[_receita_estrutura_selecionada]

	# Consome ingredientes
	for ing in rec.ingredientes:
		_jogador.inventario[ing] -= rec.ingredientes[ing]
	_jogador.inventario_atualizado.emit(_jogador.inventario)

	# Cria ItemConstrucao e adiciona ao jogador (próximo slot vazio)
	var cena_obj: PackedScene = load(rec.cena_path)
	if cena_obj == null:
		push_error("CraftingHUD: cena nao encontrada: ", rec.cena_path)
		return

	var novo_item = ItemConstrucao.new()
	novo_item.nome = rec.nome
	novo_item.cena_objeto = cena_obj
	novo_item.compensar_rotacao_90 = false
	novo_item.tamanho_grid = _extrair_tamanho_grid(cena_obj)

	_jogador.adicionar_item_construcao(novo_item)

	_atualizar_slots_estruturas()
	_atualizar_botoes_estruturas()


func _extrair_textura(node: Node) -> Texture2D:
	for child in node.find_children("*", "Sprite2D", true, false):
		return child.texture
	for child in node.find_children("*", "AnimatedSprite2D", true, false):
		if child.sprite_frames and child.sprite_frames.get_frame_texture("default", 0):
			return child.sprite_frames.get_frame_texture("default", 0)
	return null

func _extrair_tamanho_grid(cena: PackedScene) -> Vector2i:
	var inst = cena.instantiate()
	if inst == null:
		return Vector2i(1, 1)
	var val = inst.get("TAMANHO_GRID")
	inst.queue_free()
	return val if val != null else Vector2i(1, 1)
