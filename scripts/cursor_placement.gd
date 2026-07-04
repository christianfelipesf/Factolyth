class_name CursorPlacementModule extends RefCounted

const PARTICULA = preload("res://scenes/particles/particula.tscn")

var _cursor: Node


func setup(cursor: Node) -> void:
	_cursor = cursor


func get_custo_placa(nome: String) -> int:
	match nome:
		"Broca": return 2
		"Esteira": return 1
		"Nucleo": return 8
		"Canhao": return 6
		"Distribuidor": return 7
		"Cruzador": return 10
	return 0


func criar_objeto_posicionavel() -> void:
	if _cursor._eh_broca_manual():
		var jogador = _cursor.get_parent()
		if jogador.has_method("usar_broca_manual"):
			jogador.usar_broca_manual(_cursor._posicao_grid)
		_cursor._ultima_posicao_colocacao = _cursor._posicao_grid
		return

	if SaveManager.modo_jogo == "sobrevivencia":
		var custo = get_custo_placa(_cursor.item_atual.nome)
		if custo > 0:
			var jogador = _cursor.get_parent()
			var tem = int(jogador.inventario.get("placa_quartzo", 0))
			if tem < custo:
				return
			jogador.inventario["placa_quartzo"] -= custo
			jogador.inventario_atualizado.emit(jogador.inventario)

	var novo_objeto = _cursor.item_atual.cena_objeto.instantiate()
	if "is_preview" in novo_objeto:
		novo_objeto.is_preview = false
	if "esta_posicionando" in novo_objeto:
		novo_objeto.esta_posicionando = false

	var offset = -90.0 if _cursor.item_atual.compensar_rotacao_90 else 0.0
	novo_objeto.global_rotation = deg_to_rad(_cursor.rotation_atual + offset)
	novo_objeto.global_position = _cursor._posicao_grid + _cursor._grid_module.offset_colocacao()
	_cursor.get_tree().current_scene.add_child(novo_objeto)
	novo_objeto.add_to_group("estrutura")
	_spawnar_particula(novo_objeto.global_position)
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


func remover_objeto_na_posicao() -> void:
	for corpo in _cursor.area_checagem.get_overlapping_bodies():
		if corpo != _cursor.get_parent():
			_spawnar_particula(corpo.global_position)
			_cursor._audio_destruir.play()
			corpo.queue_free()
