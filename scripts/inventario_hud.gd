extends Control

const SLOT = preload("res://scenes/inventario_slot.tscn")

@onready var flow: HFlowContainer = $Margem/HFlowContainer

func _ready() -> void:
	var jogador = get_node_or_null("/root/Mundo/Jogador")
	if jogador and jogador.has_signal("inventario_atualizado"):
		jogador.inventario_atualizado.connect(_atualizar)
		_atualizar(jogador.inventario)

func _atualizar(inv: Dictionary) -> void:
	for filho in flow.get_children():
		filho.queue_free()

	for chave in inv:
		var quant = inv[chave]
		if quant <= 0:
			continue

		var dados = ItemDB.get_item(chave)

		var slot = SLOT.instantiate()
		slot.get_node("Icone").texture = dados.textura if dados else null
		slot.get_node("Nome").text = dados.nome if dados else chave
		slot.get_node("Quantidade").text = str(quant)
		flow.add_child(slot)
