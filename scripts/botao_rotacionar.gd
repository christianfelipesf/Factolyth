extends TextureButton

const DURACAO_GIRO := 0.15


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	AudioManager.play_click()
	var cursor = get_tree().get_first_node_in_group("cursor")
	if cursor != null and cursor.has_method("rotacionar"):
		cursor.rotacionar()
		_animar_rotacao()


func _animar_rotacao() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", rotation + deg_to_rad(90.0), DURACAO_GIRO)
