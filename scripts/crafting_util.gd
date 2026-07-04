class_name CraftingUtil extends RefCounted

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
