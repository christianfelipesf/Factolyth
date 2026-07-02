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
	call_deferred(&"gerar")

func _vizinhos_mesmo_tipo(pos: Vector2i, tile: Vector2i) -> int:
	var total := 0
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			if solo.get_cell_atlas_coords(pos + Vector2i(dx, dy)) == tile:
				total += 1
	return total

func gerar() -> void:
	if SaveManager != null:
		SaveManager.mostrar_carregando()
	solo.visible = false
	minerios.visible = false
	solo.clear()
	minerios.clear()

	var noise_altura := FastNoiseLite.new()
	noise_altura.seed = semente
	noise_altura.frequency = 0.015
	noise_altura.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var noise_rio := FastNoiseLite.new()
	noise_rio.seed = semente + 1
	noise_rio.frequency = 0.025
	noise_rio.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise_rio.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB

	var noise_detalhe := FastNoiseLite.new()
	noise_detalhe.seed = semente + 2
	noise_detalhe.frequency = 0.08
	noise_detalhe.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var noise_warp := FastNoiseLite.new()
	noise_warp.seed = semente + 3
	noise_warp.frequency = 0.004
	noise_warp.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var noise_minerios := FastNoiseLite.new()
	noise_minerios.seed = semente + 4
	noise_minerios.frequency = 0.04
	noise_minerios.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	var deslocamento := Vector2i(-largura / 2, -altura / 2)
	var tiles_lava: Array[Vector2i] = []
	var tiles_agua: Array[Vector2i] = []

	for x in largura:
		for y in altura:
			var warp_x: float = noise_warp.get_noise_2d(x, y) * 30.0
			var warp_y: float = noise_warp.get_noise_2d(x + 200, y + 200) * 30.0

			var px := x + warp_x
			var py := y + warp_y

			var altura_valor: float = noise_altura.get_noise_2d(px, py)
			var detalhe: float = noise_detalhe.get_noise_2d(x, y)
			var rio: float = noise_rio.get_noise_2d(px, py)
			var fundo_rio: float = 1.0 - abs(rio)

			var pos := Vector2i(x + deslocamento.x, y + deslocamento.y)

			if altura_valor < -0.3:
				solo.set_cell(pos, FONTE_TILE, AGUA)
				tiles_agua.append(pos)
			elif fundo_rio > 0.88 and altura_valor < 0.0:
				solo.set_cell(pos, FONTE_TILE, AGUA)
				tiles_agua.append(pos)
			elif altura_valor > 0.5:
				solo.set_cell(pos, FONTE_TILE, LAVA)
				tiles_lava.append(pos)
			elif fundo_rio > 0.88 and altura_valor > 0.35:
				solo.set_cell(pos, FONTE_TILE, LAVA)
				tiles_lava.append(pos)
			elif altura_valor > 0.2:
				solo.set_cell(pos, FONTE_TILE, PEDRA)
			elif detalhe < 0.0:
				solo.set_cell(pos, FONTE_TILE, PEDRA)
			else:
				solo.set_cell(pos, FONTE_TILE, GRAMA)

			var valor_minerio: float = noise_minerios.get_noise_2d(x, y)
			if abs(valor_minerio) > 0.65:
				var tile_atual := solo.get_cell_atlas_coords(pos)
				if tile_atual == GRAMA or tile_atual == PEDRA:
					var tile_minerio := BRONZE if valor_minerio > -0.7 else FERRO
					minerios.set_cell(pos, FONTE_TILE, tile_minerio)

		if x % 75 == 0:
			await get_tree().process_frame

	_limpar_ilhas(tiles_lava, LAVA, PEDRA)
	_limpar_ilhas(tiles_agua, AGUA, GRAMA)

	solo.visible = true
	minerios.visible = true
	if SaveManager != null:
		SaveManager.esconder_carregando()
	print("Mapa gerado (semente: ", semente, ")")

func _limpar_ilhas(tiles: Array[Vector2i], tile_tipo: Vector2i, tile_substituto: Vector2i) -> void:
	for pos in tiles:
		if solo.get_cell_atlas_coords(pos) != tile_tipo:
			continue
		if _vizinhos_mesmo_tipo(pos, tile_tipo) < 2:
			solo.set_cell(pos, FONTE_TILE, tile_substituto)
