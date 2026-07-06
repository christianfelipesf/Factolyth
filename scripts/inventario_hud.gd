extends Control

const SLOT = preload("res://scenes/inventario_slot.tscn")

@onready var scroll: ScrollContainer = $Margem/Scroll
@onready var grid: GridContainer = $Margem/Scroll/Grid


func _ready() -> void:
	_esconder_scrollbar()
	var jogador = get_node_or_null("/root/Mundo/Jogador")
	if jogador and jogador.has_signal("inventario_atualizado"):
		jogador.inventario_atualizado.connect(_atualizar)
		_atualizar(jogador.inventario)


func _esconder_scrollbar() -> void:
	scroll.get_v_scroll_bar().visible = false


func _atualizar(inv: Dictionary) -> void:
	for filho in grid.get_children():
		filho.queue_free()

	for chave in inv:
		var quant = inv[chave]
		if quant <= 0:
			continue

		var dados = ItemRegistry.get_item(chave)

		var slot = SLOT.instantiate()
		slot.get_node("Icone").texture = dados.textura if dados else null
		slot.get_node("Nome").text = dados.nome if dados else chave
		slot.get_node("Quantidade").text = str(quant)
		grid.add_child(slot)
