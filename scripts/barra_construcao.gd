extends Control

var _itens: Array = []
var _slots: Array[Button] = []
var _indice_selecionado: int = -1
var _jogador: Node = null

@onready var hbox: HBoxContainer = $HBoxContainer

func _ready() -> void:
	_jogador = get_tree().root.find_child("Jogador", true, false)
	if _jogador:
		if _jogador.has_method("get_itens_construcao"):
			_itens = _jogador.get_itens_construcao()
		if _jogador.has_signal("item_selecionado"):
			_jogador.item_selecionado.connect(_atualizar_destaque)
	_construir_slots()
	if _jogador and _jogador.has_method("get_indice_item_atual"):
		_atualizar_destaque(_jogador.get_indice_item_atual())

func _construir_slots() -> void:
	for s in _slots:
		s.queue_free()
	_slots.clear()

	for i in _itens.size():
		var item = _itens[i]
		var btn = Button.new()
		btn.text = item.nome + "\n[" + str(i + 1) + "]"
		btn.custom_minimum_size = Vector2(100, 56)
		btn.size_flags_horizontal = SIZE_SHRINK_CENTER
		btn.toggle_mode = true
		btn.pressed.connect(_on_slot_pressed.bind(i))
		hbox.add_child(btn)
		_slots.append(btn)

	_indice_selecionado = -1

func _atualizar_destaque(indice: int) -> void:
	_indice_selecionado = indice
	for i in _slots.size():
		_slots[i].button_pressed = (i == indice)

func _on_slot_pressed(indice: int) -> void:
	if _jogador and _jogador.has_method("selecionar_item_por_indice"):
		_jogador.selecionar_item_por_indice(indice)
