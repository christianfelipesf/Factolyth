class_name CursorGridModule extends RefCounted

var _cursor: Node


func setup(cursor: Node) -> void:
	_cursor = cursor


func recriar_indicador(tamanho: Vector2i) -> void:
	var antigo = _cursor._indicador_grid
	if antigo != null:
		antigo.queue_free()

	var px := tamanho.x * 32
	var py := tamanho.y * 32
	var img := Image.create(px, py, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	var novo = Sprite2D.new()
	novo.texture = tex
	novo.modulate = Color(0, 1, 0, 0.18)
	novo.z_index = 11
	_cursor.add_child(novo)
	_cursor._indicador_grid = novo

	var rect := RectangleShape2D.new()
	rect.size = Vector2(px - 8.0, py - 8.0)
	_cursor.shape_checagem.shape = rect


func offset_colocacao() -> Vector2:
	var tam = _cursor._tamanho_grid_atual
	return Vector2(
		(tam.x - 1) * 16.0,
		(tam.y - 1) * 16.0
	)


func atualizar_cursor_e_grid(pos_alternativa: Vector2 = Vector2.INF) -> void:
	var camera = _cursor.camera
	var alvo: Vector2
	if pos_alternativa != Vector2.INF:
		alvo = pos_alternativa
	else:
		alvo = _cursor.get_global_mouse_position()

	var tam_tela = _cursor.get_viewport_rect().size
	var area_visivel = tam_tela / camera.zoom
	var centro = camera.get_screen_center_position()
	var lim_min = centro - area_visivel / 2.0
	var lim_max = centro + area_visivel / 2.0

	_cursor.global_position = Vector2(
		clamp(alvo.x, lim_min.x, lim_max.x),
		clamp(alvo.y, lim_min.y, lim_max.y)
	)

	_cursor._posicao_grid = Vector2(
		floor(alvo.x / 32.0) * 32.0 + 16,
		floor(alvo.y / 32.0) * 32.0 + 16
	)

	var ofs := offset_colocacao()
	var pos = _cursor._posicao_grid

	if _cursor._indicador_grid != null:
		_cursor._indicador_grid.global_position = pos + ofs

	_cursor.area_checagem.global_position = pos + ofs

	for child in _cursor.get_children():
		if child.has_meta("is_construction_preview"):
			child.global_position = pos + ofs

	if _cursor._seta_direcao.visible:
		_cursor._seta_direcao.global_position = pos + ofs

	gerenciar_cor_do_preview()


func area_esta_ocupada() -> bool:
	return _cursor.area_checagem.has_overlapping_bodies()


func gerenciar_cor_do_preview() -> void:
	var item_atual = _cursor.item_atual
	if item_atual == null:
		return
	var sobre_ui: bool = _cursor._cursor_em_ui()
	if _cursor._indicador_grid != null:
		_cursor._indicador_grid.visible = not sobre_ui
	if _cursor._seta_direcao.visible and sobre_ui:
		_cursor._seta_direcao.visible = false
	for filho in _cursor.get_children():
		if filho.has_meta("is_construction_preview"):
			filho.visible = not sobre_ui
	if sobre_ui:
		return
	var ocupado := area_esta_ocupada()
	var vermelho := false
	if _cursor._eh_broca_manual():
		var jogador = _cursor.get_parent()
		vermelho = jogador.has_method("esta_em_cooldown_broca") and jogador.esta_em_cooldown_broca()
	var cor := Color(1.0, 0.3, 0.3, 0.5) if ocupado or vermelho else Color(1.0, 1.0, 1.0, 0.4)
	if _cursor._indicador_grid != null:
		_cursor._indicador_grid.modulate = Color(1.0, 0.0, 0.0, 0.18) if ocupado or vermelho else Color(0.0, 1.0, 0.0, 0.18)
	for filho in _cursor.get_children():
		if filho.has_meta("is_construction_preview"):
			filho.modulate = cor
