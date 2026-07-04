class_name CursorPlacementModule extends RefCounted

const PARTICULA = preload("res://scenes/particles/particula.tscn")

var _cursor: Node


func setup(cursor: Node) -> void:
	_cursor = cursor


func criar_objeto_posicionavel() -> void:
	if _cursor._eh_broca_manual():
		var jogador = _cursor.get_parent()
		if jogador.has_method("usar_broca_manual"):
			jogador.usar_broca_manual(_cursor._posicao_grid)
		_cursor._ultima_posicao_colocacao = _cursor._posicao_grid
		return

	var nome = _cursor.item_atual.nome
	if SaveManager.modo_jogo == "sobrevivencia":
		var custo = ItemRegistry.get_custo(nome)
		if custo > 0:
			var jogador = _cursor.get_parent()
			var tem = int(jogador.inventario.get("placa_quartzo", 0))
			if tem < custo:
				_notificar("Faltam recursos!")
				return
			jogador.inventario["placa_quartzo"] -= custo
			jogador.inventario_atualizado.emit(jogador.inventario)

	var novo_objeto = _cursor.item_atual.cena_objeto.instantiate()
	if "is_preview" in novo_objeto:
		novo_objeto.is_preview = false
	if "esta_posicionando" in novo_objeto:
		novo_objeto.esta_posicionando = true

	var offset = -90.0 if _cursor.item_atual.compensar_rotacao_90 else 0.0
	novo_objeto.global_rotation = deg_to_rad(_cursor.rotation_atual + offset)
	novo_objeto.global_position = _cursor._posicao_grid + _cursor._grid_module.offset_colocacao()

	var tempo = ItemRegistry.get_tempo_construcao(nome)
	if tempo > 0:
		_iniciar_construcao(novo_objeto, tempo)
	else:
		_finalizar_construcao(novo_objeto)


func _iniciar_construcao(objeto: Node, tempo: float) -> void:
	objeto.add_to_group("estrutura")
	_cursor.get_tree().current_scene.add_child(objeto)

	objeto.set_process(false)
	objeto.set_physics_process(false)
	objeto.modulate = Color(1, 1, 1, 0.5)

	_cursor._ultima_posicao_colocacao = _cursor._posicao_grid
	_spawnar_particula_construcao(objeto.global_position)

	await _cursor.get_tree().create_timer(tempo).timeout

	if not is_instance_valid(objeto):
		return
	objeto.modulate = Color(1, 1, 1, 1)
	if "esta_posicionando" in objeto:
		objeto.esta_posicionando = false
	objeto.set_process(true)
	objeto.set_physics_process(true)

	_finalizar_construcao(objeto)


func _finalizar_construcao(objeto: Node) -> void:
	_spawnar_particula(objeto.global_position)
	_cursor._audio_colocar.play()

	_cursor._ultima_posicao_colocacao = _cursor._posicao_grid

	await _cursor.get_tree().physics_frame
	_cursor.get_tree().call_group("broca", "verificar_extrutura_e_atualizar_estado")


func _spawnar_particula(pos: Vector2) -> void:
	var p = PARTICULA.instantiate()
	p.global_position = pos
	p.one_shot = true
	_cursor.get_tree().current_scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _spawnar_particula_construcao(pos: Vector2) -> void:
	var p = PARTICULA.instantiate()
	p.global_position = pos
	p.one_shot = true
	p.modulate = Color(0.5, 0.5, 1.0)
	_cursor.get_tree().current_scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func remover_objeto_na_posicao() -> void:
	for corpo in _cursor.area_checagem.get_overlapping_bodies():
		if corpo == _cursor.get_parent():
			continue

		_devolver_materiais(corpo)
		_spawnar_particula(corpo.global_position)
		_cursor._audio_destruir.play()
		corpo.queue_free()


func _devolver_materiais(objeto: Node) -> void:
	if SaveManager.modo_jogo != "sobrevivencia":
		return
	var path = objeto.scene_file_path
	if path.is_empty():
		return
	var receita = ItemRegistry.get_receita_por_cena(path)
	if receita.is_empty():
		return
	var jogador = _cursor.get_parent()
	for item_id in receita:
		var quant = receita[item_id]
		jogador.inventario[item_id] = jogador.inventario.get(item_id, 0) + quant
	jogador.inventario_atualizado.emit(jogador.inventario)


func _notificar(texto: String) -> void:
	var label = Label.new()
	label.text = texto
	label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	_cursor.get_tree().current_scene.add_child(label)
	label.global_position = _cursor.global_position + Vector2(-label.size.x * 0.5, -40)
	var tween = _cursor.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	if is_instance_valid(label):
		label.queue_free()
