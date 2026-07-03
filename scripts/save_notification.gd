extends Label

func _ready() -> void:
	hide()
	# Conecta ao sinal do SaveManager para notificar mesmo via F5
	if SaveManager.has_signal("save_concluido"):
		SaveManager.save_concluido.connect(_ao_salvar)


func _ao_salvar(_slot: String) -> void:
	mostrar("Salvo!", 2.0)


func mostrar(mensagem: String, duracao: float = 2.0) -> void:
	text = mensagem
	show()
	# Reseta modulação (remove fade anterior)
	modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(duracao * 0.6).timeout
	# Fade out
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
	await tween.finished
	hide()
	modulate = Color(1, 1, 1, 1)
