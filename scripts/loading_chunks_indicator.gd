extends Label

var _mapa: Node = null
var _era_visivel := false

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	if _mapa == null:
		if get_tree() != null and get_tree().current_scene != null:
			_mapa = get_tree().current_scene.get_node_or_null("Mapa")
		if _mapa == null and get_tree() != null:
			_mapa = get_tree().root.find_child("Mapa", true, false)
		if _mapa == null:
			return

	if not _mapa.has_method("esta_gerando"):
		return

	var gerando: bool = _mapa.esta_gerando()

	if gerando and not _era_visivel:
		_mostrar()
		_era_visivel = true
	elif not gerando and _era_visivel:
		_esconder()
		_era_visivel = false

func _mostrar() -> void:
	modulate = Color(1, 1, 1, 1)
	show()

func _esconder() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	hide()
	modulate = Color(1, 1, 1, 1)
