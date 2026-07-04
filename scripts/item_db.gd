extends Node

var _itens: Dictionary = {}

func _ready() -> void:
	_registrar(preload("res://resources/itens/quartzo.tres"))
	_registrar(preload("res://resources/itens/placa_quartzo.tres"))

func _registrar(data: ItemData) -> void:
	if data != null:
		_itens[data.id] = data

func get_item(id: String) -> ItemData:
	return _itens.get(id)