extends Control

@onready var fundo: ColorRect = $Fundo
@onready var painel: Panel = $Painel
@onready var vbox: VBoxContainer = $Painel/VBox
@onready var btn_itens: Button = $Painel/VBox/Abas/BtnItens
@onready var btn_estruturas: Button = $Painel/VBox/Abas/BtnEstruturas
@onready var btn_inventario: Button = $Painel/VBox/Abas/BtnInventario
@onready var conteudo_itens: VBoxContainer = $Painel/VBox/ConteudoItens
@onready var conteudo_estruturas: VBoxContainer = $Painel/VBox/ConteudoEstruturas
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
@onready var grid_slots: GridContainer = $Painel/VBox/ConteudoEstruturas/GridSlots
@onready var vbox_receitas_estrutura: VBoxContainer = $Painel/VBox/ConteudoEstruturas/ScrollEstruturas/VBoxReceitasEstrutura
@onready var btn_fabricar: Button = $Painel/VBox/ConteudoEstruturas/Fabricar

var _jogador: Node = null
var _aba_atual: String = "itens"
var _util: CraftingUtil
var _item_module: CraftingItemModule
var _estruturas_module: CraftingEstruturaModule
var _inventario_module: CraftingInventarioModule


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jogador = get_node("/root/Mundo/Jogador")
	if _jogador == null:
		printerr("CraftingHUD: jogador não encontrado")
		return

	_util = CraftingUtil.new()
	_item_module = CraftingItemModule.new()
	_item_module.setup(icone, nome_label, container_ingredientes, progresso, tempo_label, botao, vbox_receitas, _jogador, _util)
	_estruturas_module = CraftingEstruturaModule.new()
	_estruturas_module.setup(grid_slots, vbox_receitas_estrutura, btn_fabricar, _jogador, _util)
	_inventario_module = CraftingInventarioModule.new()
	_inventario_module.setup(grid_inventario, _jogador, _util)

	fundo.gui_input.connect(_on_fundo_clique)
	fechar.pressed.connect(_fechar)
	botao.pressed.connect(_item_module.iniciar_craft)
	btn_fabricar.pressed.connect(_estruturas_module.fabricar_estrutura)
	btn_itens.pressed.connect(func(): _alternar_aba("itens"))
	btn_estruturas.pressed.connect(func(): _alternar_aba("estruturas"))
	btn_inventario.pressed.connect(func(): _alternar_aba("inventario"))
	_jogador.inventario_atualizado.connect(_ao_atualizar_inventario)
	_jogador.item_selecionado.connect(_ao_atualizar_slots)
	_jogador.itens_construcao_atualizados.connect(_ao_atualizar_slots_estruturas)

	_alternar_aba("itens")


var _abas: Array[String] = ["itens", "estruturas", "inventario"]

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_fechar()
		get_viewport().set_input_as_handled()
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER:
				var idx = _abas.find(_aba_atual)
				idx = (idx - 1 + _abas.size()) % _abas.size()
				_alternar_aba(_abas[idx])
				get_viewport().set_input_as_handled()
			JOY_BUTTON_RIGHT_SHOULDER:
				var idx = _abas.find(_aba_atual)
				idx = (idx + 1) % _abas.size()
				_alternar_aba(_abas[idx])
				get_viewport().set_input_as_handled()
			JOY_BUTTON_B:
				_fechar()
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _item_module != null:
		_item_module.process(delta)


func toggle() -> void:
	if _item_module == null:
		return
	if _item_module.esta_craftando():
		return
	if visible:
		_fechar()
	else:
		_abrir()


func _abrir() -> void:
	if _item_module == null or _estruturas_module == null:
		return
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_item_module.atualizar_detalhes()
	_estruturas_module.atualizar_slots()
	_estruturas_module.atualizar_botoes()


func _fechar() -> void:
	if _item_module == null:
		return
	if _item_module.esta_craftando():
		return
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_fundo_clique(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fechar()


func _alternar_aba(aba: String) -> void:
	_aba_atual = aba
	conteudo_itens.visible = (aba == "itens")
	conteudo_estruturas.visible = (aba == "estruturas")
	conteudo_inventario.visible = (aba == "inventario")
	btn_itens.disabled = (aba == "itens")
	btn_estruturas.disabled = (aba == "estruturas")
	btn_inventario.disabled = (aba == "inventario")
	if aba in ["estruturas", "inventario"]:
		_estruturas_module.atualizar_slots()
		if aba == "inventario":
			_inventario_module.atualizar_slots()


func _ao_atualizar_inventario(_inv: Dictionary) -> void:
	if visible:
		_item_module.atualizar_detalhes()
		if _aba_atual == "estruturas":
			_estruturas_module.atualizar_botoes()


func _ao_atualizar_slots(_indice: int) -> void:
	if not visible:
		return
	_estruturas_module.atualizar_slots()
	_inventario_module.atualizar_slots()


func _ao_atualizar_slots_estruturas() -> void:
	if not visible:
		return
	_estruturas_module.atualizar_slots()
	_estruturas_module.atualizar_botoes()
	_inventario_module.atualizar_slots()
