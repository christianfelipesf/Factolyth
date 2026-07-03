extends Control

@onready var label: Label = %Label

func _ready() -> void:
	var nucleo := get_tree().root.find_child("Nucleo", true, false)
	if nucleo and nucleo.has_signal("inventario_atualizado"):
		nucleo.inventario_atualizado.connect(_atualizar)
		_atualizar(nucleo.inventario)

func _atualizar(inv: Dictionary) -> void:
	var textos: PackedStringArray = []
	for chave in inv:
		textos.append(chave.capitalize() + ": " + str(inv[chave]))
	label.text = "Inventário:\n" + "\n".join(textos) if textos else ""
