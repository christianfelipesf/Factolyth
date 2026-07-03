extends Node2D

@export var largura: int = 750
@export var altura: int = 750
@export var semente: int = 0
@export var chunk_tamanho: int = 32
@export var distancia_visual: int = 5

const FONTE_TILE: int = 0
const GRAMA: Vector2i = Vector2i(0, 0)
const PEDRA: Vector2i = Vector2i(1, 0)
const AGUA: Vector2i = Vector2i(2, 1)
const LAVA: Vector2i = Vector2i(0, 2)
const FERRO: Vector2i = Vector2i(0, 1)
const BRONZE: Vector2i = Vector2i(1, 1)

var _noise_altura: FastNoiseLite
var _noise_vale: FastNoiseLite
var _noise_detalhe: FastNoiseLite
var _noise_warp: FastNoiseLite
var _noise_minerios: FastNoiseLite
var _deslocamento: Vector2i
var _chunks_carregados: Dictionary = {}
var _ultimo_chunk: Vector2i = Vector2i(999999, 999999)
var _jogador: Node2D = null
var _fila_geracao: Array[Vector2i] = []
var _gerando: bool = false
var _loading_ativa := false
var _frames_loading := 0

signal chunks_pronto
signal chunks_iniciou

func esta_gerando() -> bool:
	return _gerando

@onready var solo: TileMapLayer = $solo
@onready var minerios: TileMapLayer = $minerios

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if semente == 0:
		semente = randi()
	_inicializar_noises()
	_deslocamento = Vector2i(int(-largura / 2.0), int(-altura / 2.0))
	# Mostra loading até os chunks iniciais terminarem
	if SaveManager != null:
		SaveManager.mostrar_carregando()
		_loading_ativa = true
	print("Mapa pronto (semente: ", semente, ")")

## Aguarda até que todos os chunks da fila tenham sido gerados.
## Lida com o caso onde o _process() ainda não rodou (autoload processa antes).
func await_chunks_pronto() -> void:
	if _gerando:
		# Já está gerando chunks — aguarda conclusão
		await chunks_pronto
	elif not is_instance_valid(_jogador):
		# Jogador ainda não encontrado — aguarda iniciar e depois concluir
		await chunks_iniciou
		if _gerando:
			await chunks_pronto
	# Se não está gerando E jogador é válido, está tudo pronto (retorna)

func _inicializar_noises() -> void:
	_noise_altura = FastNoiseLite.new()
	_noise_altura.seed = semente
	_noise_altura.frequency = 0.015
	_noise_altura.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_noise_vale = FastNoiseLite.new()
	_noise_vale.seed = semente + 2
	_noise_vale.frequency = 0.025
	_noise_vale.noise_type = FastNoiseLite.TYPE_CELLULAR
	_noise_vale.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB

	_noise_detalhe = FastNoiseLite.new()
	_noise_detalhe.seed = semente + 3
	_noise_detalhe.frequency = 0.08
	_noise_detalhe.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_noise_warp = FastNoiseLite.new()
	_noise_warp.seed = semente + 4
	_noise_warp.frequency = 0.004
	_noise_warp.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_noise_minerios = FastNoiseLite.new()
	_noise_minerios.seed = semente + 1
	_noise_minerios.frequency = 0.04
	_noise_minerios.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

func gerar(_gerenciar_loading: bool = true) -> void:
	_inicializar_noises()

func _process(_delta: float) -> void:
	# Failsafe: se o loading estiver ativo há tempo demais, força saída
	if _loading_ativa:
		_frames_loading += 1
		if _frames_loading > 600:  # ~10 segundos a 60fps
			_loading_ativa = false
			_frames_loading = 0
			if SaveManager != null:
				SaveManager.esconder_carregando()
			chunks_pronto.emit()
			return

	if not is_instance_valid(_jogador):
		_jogador = get_tree().current_scene.get_node_or_null("Jogador")
		if not is_instance_valid(_jogador):
			return

	if not _gerando:
		_atualizar_chunks()
	elif _fila_geracao.size() > 0:
		_processar_fila()
	else:
		_gerando = false
		if _loading_ativa:
			_loading_ativa = false
			_frames_loading = 0
			if SaveManager != null:
				SaveManager.esconder_carregando()
			chunks_pronto.emit()

func _atualizar_chunks() -> void:
	if not is_instance_valid(_jogador):
		return

	var pos_tilemap := solo.local_to_map(solo.to_local(_jogador.global_position))
	var grid_x := pos_tilemap.x - _deslocamento.x
	var grid_y := pos_tilemap.y - _deslocamento.y

	if grid_x < 0 or grid_x >= largura or grid_y < 0 or grid_y >= altura:
		return

	var max_chunk_x := ceili(float(largura) / chunk_tamanho) - 1
	var max_chunk_y := ceili(float(altura) / chunk_tamanho) - 1
	var chunk_atual := Vector2i(
		clampi(int(grid_x / float(chunk_tamanho)), 0, max_chunk_x),
		clampi(int(grid_y / float(chunk_tamanho)), 0, max_chunk_y)
	)

	if chunk_atual == _ultimo_chunk:
		return
	_ultimo_chunk = chunk_atual

	var chunks_manter: Dictionary = {}
	for dx in range(-distancia_visual, distancia_visual + 1):
		for dy in range(-distancia_visual, distancia_visual + 1):
			var c := Vector2i(
				clampi(chunk_atual.x + dx, 0, max_chunk_x),
				clampi(chunk_atual.y + dy, 0, max_chunk_y)
			)
			chunks_manter[c] = true

	for c in _chunks_carregados.keys():
		if not chunks_manter.has(c):
			_descarregar_chunk(c)
			_chunks_carregados.erase(c)

	var chunks_novos := false
	for c in chunks_manter.keys():
		if not _chunks_carregados.has(c):
			_fila_geracao.append(c)
			_chunks_carregados[c] = true
			_gerando = true
			chunks_novos = true
	if chunks_novos:
		chunks_iniciou.emit()

func _processar_fila() -> void:
	var por_frame := 2
	for _i in range(por_frame):
		if _fila_geracao.is_empty():
			return  # _gerando será limpo no else do _process()
		var chunk_pos: Vector2i = _fila_geracao.pop_front()
		_gerar_chunk(chunk_pos)

func _gerar_chunk(chunk_pos: Vector2i) -> void:
	var start_x := chunk_pos.x * chunk_tamanho
	var end_x := mini(start_x + chunk_tamanho, largura)
	var start_y := chunk_pos.y * chunk_tamanho
	var end_y := mini(start_y + chunk_tamanho, altura)

	var cel_agua: Array[Vector2i] = []
	var cel_lava: Array[Vector2i] = []

	for gx in range(start_x, end_x):
		for gy in range(start_y, end_y):
			var tile_pos := Vector2i(gx + _deslocamento.x, gy + _deslocamento.y)
			var n := _get_noise(gx, gy)

			if n.altura < -0.3:
				solo.set_cell(tile_pos, FONTE_TILE, AGUA)
				cel_agua.append(tile_pos)
			elif n.vale > 0.88 and n.altura < 0.0:
				solo.set_cell(tile_pos, FONTE_TILE, AGUA)
				cel_agua.append(tile_pos)
			elif n.vale > 0.88 and n.altura > 0.35:
				solo.set_cell(tile_pos, FONTE_TILE, LAVA)
				cel_lava.append(tile_pos)
			elif n.altura > 0.5:
				solo.set_cell(tile_pos, FONTE_TILE, LAVA)
				cel_lava.append(tile_pos)
			elif n.altura > 0.2:
				solo.set_cell(tile_pos, FONTE_TILE, PEDRA)
			elif n.detalhe < 0.0:
				solo.set_cell(tile_pos, FONTE_TILE, PEDRA)
			else:
				solo.set_cell(tile_pos, FONTE_TILE, GRAMA)

			if absf(n.minerio) > 0.65:
				if n.minerio > -0.7:
					minerios.set_cell(tile_pos, FONTE_TILE, BRONZE)
				else:
					minerios.set_cell(tile_pos, FONTE_TILE, FERRO)

	_limpar_ilhas_no_chunk(cel_lava, LAVA, PEDRA)
	_limpar_ilhas_no_chunk(cel_agua, AGUA, GRAMA)

func _get_noise(grid_x: int, grid_y: int) -> Dictionary:
	var px := grid_x + _noise_warp.get_noise_2d(grid_x, grid_y) * 30.0
	var py := grid_y + _noise_warp.get_noise_2d(grid_x + 200, grid_y + 200) * 30.0
	return {
		altura = _noise_altura.get_noise_2d(px, py),
		detalhe = _noise_detalhe.get_noise_2d(grid_x, grid_y),
		vale = 1.0 - absf(_noise_vale.get_noise_2d(px, py)),
		minerio = _noise_minerios.get_noise_2d(grid_x, grid_y),
	}

func _limpar_ilhas_no_chunk(celulas: Array[Vector2i], tile_tipo: Vector2i, tile_substituto: Vector2i) -> void:
	if celulas.is_empty():
		return
	for pos in celulas:
		if solo.get_cell_atlas_coords(pos) != tile_tipo:
			continue
		var vizinhos := 0
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				if solo.get_cell_atlas_coords(pos + Vector2i(dx, dy)) == tile_tipo:
					vizinhos += 1
					if vizinhos >= 2:
						break
			if vizinhos >= 2:
				break
		if vizinhos < 2:
			solo.set_cell(pos, FONTE_TILE, tile_substituto)

func _descarregar_chunk(chunk_pos: Vector2i) -> void:
	var start_x := chunk_pos.x * chunk_tamanho
	var end_x := mini(start_x + chunk_tamanho, largura)
	var start_y := chunk_pos.y * chunk_tamanho
	var end_y := mini(start_y + chunk_tamanho, altura)
	for gx in range(start_x, end_x):
		for gy in range(start_y, end_y):
			var tile_pos := Vector2i(gx + _deslocamento.x, gy + _deslocamento.y)
			solo.set_cell(tile_pos, -1)
			minerios.set_cell(tile_pos, -1)
