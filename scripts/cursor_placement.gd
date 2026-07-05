class_name CursorPlacementModule extends RefCounted

const PARTICULA = preload("res://scenes/particles/particula.tscn")

var _cursor: Node
var _destruicoes_pendentes: Dictionary = {}
var _construcoes_em_andamento: Dictionary = {}
var _ultimo_tempo_remocao: float = -INF


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
		var receita = ItemRegistry.get_receita_por_nome(nome)
		if not receita.is_empty():
			var jogador = _cursor.get_parent()
			var faltando: Array[String] = []
			for item_id in receita:
				var necessario = receita[item_id]
				var tem = int(jogador.inventario.get(item_id, 0))
				if tem < necessario:
					var item = ItemRegistry.get_item(item_id)
					var nome_item = item.nome if item else item_id
					faltando.append("%d %s" % [necessario - tem, nome_item])
			if not faltando.is_empty():
				_notificar("Faltam " + ", ".join(faltando) + "!")
				_cursor._ultima_posicao_colocacao = _cursor._posicao_grid
				return
			for item_id in receita:
				var necessario = receita[item_id]
				jogador.inventario[item_id] = jogador.inventario.get(item_id, 0) - necessario
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
	var alvo = objeto.global_position

	await ItemFlyModule.criar_e_levar(_cursor.get_tree(), objeto, alvo)

	objeto.global_position = alvo
	_cursor.get_tree().current_scene.add_child(objeto)
	objeto.set_process(false)
	objeto.set_physics_process(false)
	objeto.modulate = Color(1, 1, 1, 0.5)

	_cursor._ultima_posicao_colocacao = _cursor._posicao_grid
	_spawnar_particula_construcao(objeto.global_position)

	var id = objeto.get_instance_id()
	_construcoes_em_andamento[id] = true

	var timer_label = _criar_timer_label(objeto, Color(0.5, 0.5, 1.0))
	_animar_timer_label(timer_label, tempo)

	await _cursor.get_tree().create_timer(tempo).timeout

	_construcoes_em_andamento.erase(id)

	if not is_instance_valid(objeto):
		return
	if objeto.get_meta("construcao_cancelada", false):
		objeto.queue_free()
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
	Input.start_joy_vibration(0, 0.3, 0.3, 0.15)

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


func remover_objeto_na_posicao(nova_interacao: bool = true) -> void:
	if not nova_interacao:
		return

	var agora = Time.get_ticks_msec() / 1000.0
	if agora - _ultimo_tempo_remocao < 0.1:
		return
	_ultimo_tempo_remocao = agora

	var corpos = _buscar_alvos()
	if corpos.is_empty():
		return

	for corpo in corpos:
		var id = corpo.get_instance_id()
		if _destruicoes_pendentes.has(id):
			continue

		if _construcoes_em_andamento.has(id):
			corpo.set_meta("construcao_cancelada", true)
			_devolver_materiais(corpo)
			_spawnar_particula(corpo.global_position)
			_cursor._audio_destruir.play()
			continue

		var nome = ItemRegistry.get_nome_por_cena(corpo.scene_file_path)
		var tempo = ItemRegistry.get_tempo_construcao(nome)
		if tempo > 0:
			_iniciar_destruicao(corpo, tempo)
		else:
			_finalizar_destruicao(corpo)


func _buscar_alvos() -> Array[Node2D]:
	var pos = _cursor.get_global_mouse_position()
	var tree = _cursor.get_tree()
	for grupo in ["item", "estrutura"]:
		var encontrados: Array[Node2D] = []
		var menor_dist = 36.0
		for no in tree.get_nodes_in_group(grupo):
			if is_instance_valid(no) and no is Node2D:
				var dist = no.global_position.distance_to(pos)
				if dist < menor_dist:
					encontrados = [no]
					menor_dist = dist
				elif dist < menor_dist + 0.01:
					encontrados.append(no)
		if not encontrados.is_empty():
			return encontrados
	return []





func _iniciar_destruicao(objeto: Node, tempo: float) -> void:
	var id = objeto.get_instance_id()
	if _destruicoes_pendentes.has(id):
		return

	objeto.set_process(false)
	objeto.set_physics_process(false)
	objeto.modulate = Color(1, 0.3, 0.3, 0.5)

	_spawnar_particula_construcao(objeto.global_position)

	var timer = _cursor.get_tree().create_timer(tempo)
	var timer_label = _criar_timer_label(objeto, Color(1, 0.3, 0.3))
	_destruicoes_pendentes[id] = {objeto = objeto, timer = timer, timer_label = timer_label}
	timer.timeout.connect(_on_timer_destruicao.bind(id, timer))

	_animar_timer_label(timer_label, tempo)


func _on_timer_destruicao(id: int, timer: SceneTreeTimer) -> void:
	var entry = _destruicoes_pendentes.get(id)
	if entry == null:
		return
	if entry.timer != timer:
		return

	_destruicoes_pendentes.erase(id)

	var objeto = entry.objeto
	if not is_instance_valid(objeto):
		return

	_finalizar_destruicao(objeto)


func _cancelar_destruicao(id: int) -> void:
	if not _destruicoes_pendentes.has(id):
		return

	var entry = _destruicoes_pendentes[id]
	_destruicoes_pendentes.erase(id)

	var objeto = entry.objeto
	if not is_instance_valid(objeto):
		return

	if is_instance_valid(entry.timer_label):
		entry.timer_label.queue_free()

	objeto.set_process(true)
	objeto.set_physics_process(true)
	objeto.modulate = Color(1, 1, 1, 1)
	_notificar("Destruição cancelada!")


func _finalizar_destruicao(objeto: Node) -> void:
	ItemFlyModule.criar_e_trazer(_cursor.get_tree(), objeto)
	_devolver_materiais(objeto)
	_spawnar_particula(objeto.global_position)
	_cursor._audio_destruir.play()
	Input.start_joy_vibration(0, 0.5, 0.5, 0.2)
	objeto.queue_free()


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


func _criar_timer_label(objeto: Node, cor: Color) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	objeto.add_child(label)
	label.position = Vector2(0, -20)
	return label


func _animar_timer_label(label: Label, duracao: float) -> void:
	var restante = duracao
	while restante > 0:
		if not is_instance_valid(label):
			return
		label.text = str(snapped(restante, 0.1)) + "s"
		await _cursor.get_tree().create_timer(0.1).timeout
		restante -= 0.1
	if is_instance_valid(label):
		label.queue_free()


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
