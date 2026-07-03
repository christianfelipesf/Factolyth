extends TouchScreenButton

## Área morta: pixels extras ao redor do botão que bloqueiam colocação de bloco.
## O botão em si usa a action "pausa" configurada no Inspector.

@export var margem_antecipacao := 20.0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _area_morta().has_point(event.position):
			get_viewport().set_input_as_handled()


func _area_morta() -> Rect2:
	var tam := _tamanho_textura()
	var pos := global_position - tam * 0.5 - Vector2.ONE * margem_antecipacao
	return Rect2(pos, tam + Vector2.ONE * margem_antecipacao * 2.0)


func _tamanho_textura() -> Vector2:
	if texture_normal != null:
		return texture_normal.get_size()
	return Vector2(32, 32)
