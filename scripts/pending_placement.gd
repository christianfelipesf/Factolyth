class_name PendingPlacementModule extends RefCounted

signal pendentes_alterados(quantia: int)

const PARTICULA = preload("res://scenes/particles/particula.tscn")

var _cursor: Node
var _pendentes: Array[Node] = []


func setup(cursor: Node) -> void:
	_cursor = cursor


func adicionar_pendente(objeto: Node) -> void:
	objeto.modulate = Color(0.3, 1.0, 0.3, 0.5)
	objeto.set_meta("is_pending_placement", true)
	if _cursor.item_atual != null:
		objeto.set_meta("item_nome", _cursor.item_atual.nome)
	objeto.add_to_group("estrutura")
	_cursor.get_tree().current_scene.add_child(objeto)
	objeto.set_process(false)
	objeto.set_physics_process(false)
	_pendentes.append(objeto)
	pendentes_alterados.emit(_pendentes.size())


func confirmar_pendentes() -> void:
	if _pendentes.is_empty():
		return

	if SaveManager.modo_jogo == "sobrevivencia":
		if not _deduzir_custo_pendentes():
			return

	var pos_centro := Vector2.ZERO
	var count := 0
	for obj in _pendentes:
		if not is_instance_valid(obj):
			continue
		obj.modulate = Color(1, 1, 1, 1)
		obj.set_meta("is_pending_placement", false)
		if "esta_posicionando" in obj:
			obj.esta_posicionando = false
		obj.set_process(true)
		obj.set_physics_process(true)
		pos_centro += obj.global_position
		count += 1

	if count > 0:
		pos_centro /= count
		_spawnar_particula(pos_centro)
		_cursor._audio_colocar.play()
		Input.start_joy_vibration(0, 0.3, 0.3, 0.15)

	_pendentes.clear()
	pendentes_alterados.emit(0)

	await _cursor.get_tree().physics_frame
	_cursor.get_tree().call_group("broca", "verificar_extrutura_e_atualizar_estado")


func cancelar_pendentes() -> void:
	if _pendentes.is_empty():
		return

	for obj in _pendentes:
		if is_instance_valid(obj):
			obj.queue_free()

	_pendentes.clear()
	pendentes_alterados.emit(0)


func tem_pendentes() -> bool:
	return not _pendentes.is_empty()


func qtd_pendentes() -> int:
	return _pendentes.size()


func _deduzir_custo_pendentes() -> bool:
	var custo_total: Dictionary = {}
	var jogador = _cursor.get_parent()

	for obj in _pendentes:
		if not is_instance_valid(obj):
			continue
		var nome = obj.get_meta("item_nome", "")
		if nome.is_empty():
			continue
		var receita = ItemRegistry.get_receita_por_nome(nome)
		if receita.is_empty():
			continue
		for item_id in receita:
			custo_total[item_id] = custo_total.get(item_id, 0) + receita[item_id]

	var faltando: Array[String] = []
	for item_id in custo_total:
		var necessario = custo_total[item_id]
		var tem = int(jogador.inventario.get(item_id, 0))
		if tem < necessario:
			var item = ItemRegistry.get_item(item_id)
			var nome_item = item.nome if item else item_id
			faltando.append("%d %s" % [necessario - tem, nome_item])

	if not faltando.is_empty():
		_cursor._placement_module._notificar("Faltam " + ", ".join(faltando) + "!")
		return false

	for item_id in custo_total:
		jogador.inventario[item_id] = jogador.inventario.get(item_id, 0) - custo_total[item_id]
	jogador.inventario_atualizado.emit(jogador.inventario)
	return true


func _spawnar_particula(pos: Vector2) -> void:
	var p = PARTICULA.instantiate()
	p.global_position = pos
	p.one_shot = true
	_cursor.get_tree().current_scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
