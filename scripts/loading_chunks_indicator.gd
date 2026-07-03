extends Label

func _ready() -> void:
	hide()
	# Conecta aos sinais do mapa para mostrar/esconder durante carregamento
	var mapa := get_tree().current_scene.get_node_or_null("Mapa")
	if mapa != null:
		if mapa.has_signal("chunks_iniciou"):
			mapa.chunks_iniciou.connect(_mostrar)
		if mapa.has_signal("chunks_pronto"):
			mapa.chunks_pronto.connect(_esconder)

func _mostrar() -> void:
	modulate = Color(1, 1, 1, 1)
	show()

func _esconder() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished
	hide()
	modulate = Color(1, 1, 1, 1)
