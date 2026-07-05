class_name CursorPreviewModule extends RefCounted

var _cursor: Node


func setup(cursor: Node) -> void:
	_cursor = cursor


func atualizar_preview_visual() -> void:
	for child in _cursor.get_children():
		if child.has_meta("is_construction_preview"):
			child.queue_free()

	if _cursor.item_atual == null or _cursor.item_atual.cena_objeto == null:
		_cursor._seta_direcao.visible = false
		return

	_cursor._seta_direcao.visible = true
	_cursor._seta_direcao.rotation = deg_to_rad(_cursor.rotation_atual)

	var obj_temp = _cursor.item_atual.cena_objeto.instantiate()
	if "is_preview" in obj_temp:
		obj_temp.is_preview = true

	var sprite = obj_temp.find_child("*AnimatedSprite2D*", true, false)
	if sprite == null:
		sprite = obj_temp.find_child("*Sprite2D*", true, false)

	if sprite != null:
		var preview = sprite.duplicate() as CanvasItem
		preview.set_meta("is_construction_preview", true)
		if _cursor.tem_modo_destruir():
			preview.modulate = Color(1.0, 0.2, 0.2, 0.4)
		else:
			preview.modulate.a = 0.4
		_preview_no_set_rotation(preview)
		preview.global_position = _cursor._posicao_grid + _cursor._grid_module.offset_colocacao()
		_cursor.add_child(preview)
		if preview.has_method("play"):
			preview.play()

	obj_temp.queue_free()


func _preview_no_set_rotation(preview: CanvasItem) -> void:
	var offset = -90.0 if _cursor.item_atual.compensar_rotacao_90 else 0.0
	preview.rotation = deg_to_rad(_cursor.rotation_atual + offset)
