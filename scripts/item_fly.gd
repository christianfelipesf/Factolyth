class_name ItemFlyModule extends RefCounted


static func _extrair_icon(objeto: Node) -> Node2D:
	var no = objeto.find_child("AnimatedSprite2D", true, false)
	if no == null:
		no = objeto.find_child("Sprite2D", true, false)
	if no == null:
		return null
	var icon = (no as Node2D).duplicate()
	icon.scale = Vector2(0.5, 0.5)
	icon.z_index = 999
	return icon


static func criar_e_levar(arvore: SceneTree, objeto: Node, destino: Vector2) -> void:
	var icon = _extrair_icon(objeto)
	var jogador = _buscar_jogador(arvore)
	if icon == null or jogador == null:
		return
	icon.global_position = jogador.global_position
	arvore.current_scene.add_child(icon)
	await arvore.create_timer(0.01).timeout
	var tween = arvore.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(icon, "global_position", destino, 0.12)
	await tween.finished
	icon.queue_free()


static func criar_e_trazer(arvore: SceneTree, objeto: Node) -> void:
	var icon = _extrair_icon(objeto)
	var jogador = _buscar_jogador(arvore)
	if icon == null or jogador == null:
		return
	icon.global_position = objeto.global_position
	arvore.current_scene.add_child(icon)
	await arvore.create_timer(0.01).timeout
	var tween = arvore.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(icon, "global_position", jogador.global_position, 0.12)
	await tween.finished
	icon.queue_free()


static func _buscar_jogador(arvore: SceneTree) -> Node2D:
	var j = arvore.get_first_node_in_group("jogador")
	if j == null:
		j = arvore.current_scene.find_child("Jogador", true, false)
	return j as Node2D
