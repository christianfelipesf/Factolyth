extends ExtratorBase

func _ready() -> void:
	tempo_producao = 3.0
	super()

func _get_item_id_default() -> String:
	return "areia"
