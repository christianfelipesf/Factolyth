class_name CraftingUtil extends RefCounted

const PARTICULA = preload("res://scenes/particles/particula.tscn")

func extrair_textura(node: Node) -> Texture2D:
	for child in node.find_children("*", "Sprite2D", true, false):
		return child.texture
	for child in node.find_children("*", "AnimatedSprite2D", true, false):
		if child.sprite_frames and child.sprite_frames.get_frame_texture("default", 0):
			return child.sprite_frames.get_frame_texture("default", 0)
	return null

func extrair_tamanho_grid(cena: PackedScene) -> Vector2i:
	var inst = cena.instantiate()
	if inst == null:
		return Vector2i(1, 1)
	var val = inst.get("TAMANHO_GRID")
	inst.queue_free()
	return val if val != null else Vector2i(1, 1)


static func deduzir_materiais(inventario: Dictionary, custo: Dictionary, notificar: Callable) -> bool:
	var faltando: Array[String] = []
	for item_id in custo:
		var necessario = custo[item_id]
		var tem = int(inventario.get(item_id, 0))
		if tem < necessario:
			var item = ItemRegistry.get_item(item_id)
			var nome_item = item.nome if item else item_id
			faltando.append("%d %s" % [necessario - tem, nome_item])
	if not faltando.is_empty():
		notificar.call("Faltam " + ", ".join(faltando) + "!")
		return false
	for item_id in custo:
		inventario[item_id] = inventario.get(item_id, 0) - custo[item_id]
	return true


static func spawnar_particula(arvore: SceneTree, pos: Vector2, cor: Color = Color.WHITE) -> void:
	var p = PARTICULA.instantiate()
	p.global_position = pos
	p.one_shot = true
	if cor != Color.WHITE:
		p.modulate = cor
	arvore.current_scene.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)