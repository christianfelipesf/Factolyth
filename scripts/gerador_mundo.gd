extends Node2D

@export var largura: int = 750
@export var altura: int = 750
@export var semente: int = 0

const FONTE_TILE: int = 0

const GRAMA: Vector2i = Vector2i(0, 0)
const PEDRA: Vector2i = Vector2i(1, 0)
const AGUA: Vector2i = Vector2i(2, 1)
const LAVA: Vector2i = Vector2i(0, 2)
const FERRO: Vector2i = Vector2i(0, 1)
const BRONZE: Vector2i = Vector2i(1, 1)

@onready var solo: TileMapLayer = $solo
@onready var minerios: TileMapLayer = $minerios

func _ready() -> void:
	if semente == 0:
		semente = randi()
	if SaveManager != null:
		SaveManager.mostrar_carregando()
	call_deferred(&"gerar")

func gerar(gerenciar_loading: bool = true) -> void:
	if gerenciar_loading and SaveManager != null:
		SaveManager.mostrar_carregando()
	await get_tree().process_frame

	var noise_altura := FastNoiseLite.new()
	noise_altura.seed = semente
	noise_altura.frequency = 0.015
	noise_altura.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var noise_vale := FastNoiseLite.new()
	noise_vale.seed = semente + 2
	noise_vale.frequency = 0.025
	noise_vale.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise_vale.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB

	var noise_detalhe := FastNoiseLite.new()
	noise_detalhe.seed = semente + 3
	noise_detalhe.frequency = 0.08
	noise_detalhe.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var noise_warp := FastNoiseLite.new()
	noise_warp.seed = semente + 4
	noise_warp.frequency = 0.004
	noise_warp.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var noise_minerios := FastNoiseLite.new()
	noise_minerios.seed = semente + 1
	noise_minerios.frequency = 0.04
	noise_minerios.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var total := largura * altura
	var cache_altura := PackedFloat32Array()
	var cache_detalhe := PackedFloat32Array()
	var cache_vale := PackedFloat32Array()
	var cache_minerio := PackedFloat32Array()
	cache_altura.resize(total)
	cache_detalhe.resize(total)
	cache_vale.resize(total)
	cache_minerio.resize(total)

	var idx := 0
	for x in largura:
		for y in altura:
			var px := x + noise_warp.get_noise_2d(x, y) * 30.0
			var py := y + noise_warp.get_noise_2d(x + 200, y + 200) * 30.0
			cache_altura[idx] = noise_altura.get_noise_2d(px, py)
			cache_detalhe[idx] = noise_detalhe.get_noise_2d(x, y)
			cache_vale[idx] = 1.0 - abs(noise_vale.get_noise_2d(px, py))
			cache_minerio[idx] = noise_minerios.get_noise_2d(x, y)
			idx += 1
		if x % 5 == 0:
			await get_tree().process_frame

	var deslocamento := Vector2i(-largura / 2, -altura / 2)

	var cel_agua: Array[Vector2i] = []
	var cel_pedra: Array[Vector2i] = []
	var cel_lava: Array[Vector2i] = []

	idx = 0
	for x in largura:
		for y in altura:
			if x % 5 == 0 and y == 0:
				await get_tree().process_frame
			var pos := Vector2i(x + deslocamento.x, y + deslocamento.y)
			var altura_valor := cache_altura[idx]
			var detalhe := cache_detalhe[idx]
			var fundo_vale := cache_vale[idx]

			if altura_valor < -0.3:
				solo.set_cell(pos, FONTE_TILE, AGUA)
				cel_agua.append(pos)
			elif fundo_vale > 0.88 and altura_valor < 0.0:
				solo.set_cell(pos, FONTE_TILE, AGUA)
				cel_agua.append(pos)
			elif fundo_vale > 0.88 and altura_valor > 0.35:
				solo.set_cell(pos, FONTE_TILE, LAVA)
				cel_lava.append(pos)
			elif altura_valor > 0.5:
				solo.set_cell(pos, FONTE_TILE, LAVA)
				cel_lava.append(pos)
			elif altura_valor > 0.2:
				solo.set_cell(pos, FONTE_TILE, PEDRA)
				cel_pedra.append(pos)
			elif detalhe < 0.0:
				solo.set_cell(pos, FONTE_TILE, PEDRA)
				cel_pedra.append(pos)
			else:
				solo.set_cell(pos, FONTE_TILE, GRAMA)

			var valor_minerio := cache_minerio[idx]
			if abs(valor_minerio) > 0.65:
				var tile_topo := GRAMA
				if altura_valor > 0.2 or detalhe < 0.0:
					tile_topo = PEDRA
				if tile_topo == GRAMA or tile_topo == PEDRA:
					if valor_minerio > -0.7:
						minerios.set_cell(pos, FONTE_TILE, BRONZE)
					else:
						minerios.set_cell(pos, FONTE_TILE, FERRO)

			idx += 1

	_limpar_ilhas(cel_lava, LAVA, PEDRA)
	_limpar_ilhas(cel_agua, AGUA, GRAMA)

	await get_tree().process_frame

	if gerenciar_loading and SaveManager != null:
		SaveManager.esconder_carregando()
	print("Mapa gerado (semente: ", semente, ")")

func _limpar_ilhas(celulas: Array[Vector2i], tile_tipo: Vector2i, tile_substituto: Vector2i) -> void:
	if celulas.is_empty():
		return
	var conjunto := PackedVector2Array(celulas)
	for i in range(celulas.size()):
		var pos := celulas[i]
		if i % 200 == 0:
			await get_tree().process_frame
		if solo.get_cell_atlas_coords(pos) != tile_tipo:
			continue
		var vizinhos := 0
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				if conjunto.has(pos + Vector2i(dx, dy)):
					vizinhos += 1
					if vizinhos >= 2:
						break
			if vizinhos >= 2:
				break
		if vizinhos < 2:
			solo.set_cell(pos, FONTE_TILE, tile_substituto)
