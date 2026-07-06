class_name StructureFactory extends RefCounted

static func criar(nome: String, cena_objeto: PackedScene, posicao: Vector2, rotacao: float, compensar_rotacao_90: bool) -> Node:
	var objeto = cena_objeto.instantiate()
	if "is_preview" in objeto:
		objeto.is_preview = false
	if "esta_posicionando" in objeto:
		objeto.esta_posicionando = true
	var offset = -90.0 if compensar_rotacao_90 else 0.0
	objeto.global_rotation = deg_to_rad(rotacao + offset)
	objeto.global_position = posicao
	objeto.add_to_group("estrutura")
	return objeto


static func criar_com_offset(nome: String, cena_objeto: PackedScene, posicao_grid: Vector2, rotacao: float, compensar_rotacao_90: bool, offset_colocacao: Vector2) -> Node:
	return criar(nome, cena_objeto, posicao_grid + offset_colocacao, rotacao, compensar_rotacao_90)