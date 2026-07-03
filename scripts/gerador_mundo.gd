extends Node2D

@export var largura: int = 750
@export var altura: int = 750
@export var semente: int = 0
@export var chunk_tamanho: int = 32
@export var distancia_visual: int = 5
@export_file("*.json") var config_carregar: String = ""

@export_group("Noises")
@export_range(0.001, 0.1, 0.001) var freq_altura: float = 0.015
@export_range(0.001, 0.1, 0.001) var freq_bioma: float = 0.02
@export_range(0.001, 0.1, 0.001) var freq_vale: float = 0.025
@export_range(0.001, 0.2, 0.001) var freq_detalhe: float = 0.08
@export_range(0.001, 0.05, 0.001) var freq_warp: float = 0.004
@export_range(0.001, 0.2, 0.001) var freq_minerio: float = 0.05
@export_range(1, 100, 1) var warp_magnitude: float = 30.0

@export_group("Biomas")
@export_range(0.0, 0.8, 0.01) var pedra_altura_limiar: float = 0.35
@export_range(0.0, 1.0, 0.05) var cogumelo_detalhe_peso: float = 0.3
@export_range(-1.0, 1.0, 0.01) var cogumelo_limiar: float = -0.3

@export_group("Líquidos")
@export_range(-0.8, 0.0, 0.01) var agua_altura_limiar: float = -0.3
@export_range(0.5, 1.0, 0.01) var agua_vale_limiar: float = 0.88
@export_range(0.0, 1.0, 0.01) var lava_altura_limiar: float = 0.5
@export_range(-0.5, 0.8, 0.01) var lava_cogumelo_altura: float = 0.2

@export_group("Cristais")
@export_range(0.1, 1.0, 0.01) var cristal_noise_min: float = 0.6
@export_range(0.1, 1.0, 0.01) var cristal_raro_noise_min: float = 0.7

const FONTE_SOLO: int = 0
const FONTE_CRISTAIS: int = 1
const GRAMA: Vector2i = Vector2i(0, 0)
const COGUMELO: Vector2i = Vector2i(1, 0)
const PEDRA: Vector2i = Vector2i(0, 2)
const AGUA: Vector2i = Vector2i(1, 2)
const LAVA: Vector2i = Vector2i(2, 2)
const QUARTZO: Vector2i = Vector2i(1, 0)
const RUBELITA: Vector2i = Vector2i(0, 1)
const TURMALINA_CIANO: Vector2i = Vector2i(0, 2)

var _noise_altura: FastNoiseLite
var _noise_vale: FastNoiseLite
var _noise_detalhe: FastNoiseLite
var _noise_warp: FastNoiseLite
var _noise_minerios: FastNoiseLite
var _noise_bioma: FastNoiseLite

func carregar_config(caminho_arquivo: String) -> void:
	var arquivo := FileAccess.open(caminho_arquivo, FileAccess.READ)
	if arquivo == null:
		push_error("Falha ao abrir config: ", caminho_arquivo)
		return
	var json_str := arquivo.get_as_text()
	arquivo.close()
	var json := JSON.new()
	var erro := json.parse(json_str)
	if erro != OK:
		push_error("Falha ao parsear config JSON: ", erro)
		return
	var dados = json.data
	if dados.has("seed"): semente = dados.seed
	if dados.has("fAlt"): freq_altura = dados.fAlt
	if dados.has("fBio"): freq_bioma = dados.fBio
	if dados.has("fVale"): freq_vale = dados.fVale
	if dados.has("fDet"): freq_detalhe = dados.fDet
	if dados.has("fWarp"): freq_warp = dados.fWarp
	if dados.has("fMin"): freq_minerio = dados.fMin
	if dados.has("wMag"): warp_magnitude = dados.wMag
	if dados.has("bPedra"): pedra_altura_limiar = dados.bPedra
	if dados.has("bCogDet"): cogumelo_detalhe_peso = dados.bCogDet
	if dados.has("bCog"): cogumelo_limiar = dados.bCog
	if dados.has("lAgua1"): agua_altura_limiar = dados.lAgua1
	if dados.has("lAguaV"): agua_vale_limiar = dados.lAguaV
	if dados.has("lLavaA"): lava_altura_limiar = dados.lLavaA
	if dados.has("lLavaCog"): lava_cogumelo_altura = dados.lLavaCog
	if dados.has("cMin"): cristal_noise_min = dados.cMin
	if dados.has("cMinRaro"): cristal_raro_noise_min = dados.cMinRaro
	print("Config carregada de: ", caminho_arquivo)

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
	if SaveManager != null and not SaveManager.modo_procedural:
		return false
	return _gerando

@onready var solo: TileMapLayer = $solo
@onready var cristais: TileMapLayer = $cristais

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if SaveManager != null and not SaveManager.modo_procedural:
		return
	if semente == 0:
		semente = randi()
	if config_carregar != "":
		carregar_config(config_carregar)
	_inicializar_noises()
	_deslocamento = Vector2i(int(-largura / 2.0), int(-altura / 2.0))
	if SaveManager != null:
		SaveManager.mostrar_carregando()
		_loading_ativa = true
	print("Mapa pronto (semente: ", semente, ")")

func await_chunks_pronto() -> void:
	if SaveManager != null and not SaveManager.modo_procedural:
		return
	if _gerando:
		await chunks_pronto
	elif not is_instance_valid(_jogador):
		await chunks_iniciou
		if _gerando:
			await chunks_pronto

func _inicializar_noises() -> void:
	_noise_altura = FastNoiseLite.new()
	_noise_altura.seed = semente
	_noise_altura.frequency = freq_altura
	_noise_altura.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_noise_vale = FastNoiseLite.new()
	_noise_vale.seed = semente + 2
	_noise_vale.frequency = freq_vale
	_noise_vale.noise_type = FastNoiseLite.TYPE_CELLULAR
	_noise_vale.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB

	_noise_detalhe = FastNoiseLite.new()
	_noise_detalhe.seed = semente + 3
	_noise_detalhe.frequency = freq_detalhe
	_noise_detalhe.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_noise_warp = FastNoiseLite.new()
	_noise_warp.seed = semente + 4
	_noise_warp.frequency = freq_warp
	_noise_warp.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_noise_minerios = FastNoiseLite.new()
	_noise_minerios.seed = semente + 1
	_noise_minerios.frequency = freq_minerio
	_noise_minerios.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_noise_bioma = FastNoiseLite.new()
	_noise_bioma.seed = semente + 5
	_noise_bioma.frequency = freq_bioma
	_noise_bioma.noise_type = FastNoiseLite.TYPE_CELLULAR
	_noise_bioma.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	_noise_bioma.cellular_jitter = 0.6

func gerar(_gerenciar_loading: bool = true) -> void:
	_inicializar_noises()

func _process(_delta: float) -> void:
	if SaveManager != null and not SaveManager.modo_procedural:
		return
	if _loading_ativa:
		_frames_loading += 1
		if _frames_loading > 600:
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
			return
		var chunk_pos: Vector2i = _fila_geracao.pop_front()
		_gerar_chunk(chunk_pos)

func _get_bioma(altura: float, bioma_noise: float, detalhe: float) -> Vector2i:
	if altura > pedra_altura_limiar:
		return PEDRA
	if bioma_noise + detalhe * cogumelo_detalhe_peso < cogumelo_limiar:
		return COGUMELO
	return GRAMA

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

			var bioma := _get_bioma(n.altura, n.bioma, n.detalhe)
			solo.set_cell(tile_pos, FONTE_SOLO, bioma)

			var eh_liquido := false
			if n.altura < agua_altura_limiar:
				solo.set_cell(tile_pos, FONTE_SOLO, AGUA)
				cel_agua.append(tile_pos)
				eh_liquido = true
			elif n.vale > agua_vale_limiar and n.altura < 0.0:
				solo.set_cell(tile_pos, FONTE_SOLO, AGUA)
				cel_agua.append(tile_pos)
				eh_liquido = true
			elif n.altura > lava_altura_limiar:
				solo.set_cell(tile_pos, FONTE_SOLO, LAVA)
				cel_lava.append(tile_pos)
				eh_liquido = true
			elif n.vale > agua_vale_limiar and n.altura > 0.35:
				solo.set_cell(tile_pos, FONTE_SOLO, LAVA)
				cel_lava.append(tile_pos)
				eh_liquido = true
			elif bioma == COGUMELO and n.altura > lava_cogumelo_altura:
				solo.set_cell(tile_pos, FONTE_SOLO, LAVA)
				cel_lava.append(tile_pos)
				eh_liquido = true

			if not eh_liquido and absf(n.minerio) > cristal_noise_min:
				if bioma == GRAMA:
					cristais.set_cell(tile_pos, FONTE_CRISTAIS, QUARTZO)
				elif bioma == COGUMELO and absf(n.minerio) > cristal_raro_noise_min:
					cristais.set_cell(tile_pos, FONTE_CRISTAIS, RUBELITA)
				elif bioma == PEDRA and absf(n.minerio) > cristal_raro_noise_min:
					cristais.set_cell(tile_pos, FONTE_CRISTAIS, TURMALINA_CIANO)

	_limpar_ilhas_no_chunk(cel_lava, LAVA, PEDRA)
	_limpar_ilhas_no_chunk(cel_agua, AGUA, GRAMA)

func _get_noise(grid_x: int, grid_y: int) -> Dictionary:
	var px := grid_x + _noise_warp.get_noise_2d(grid_x, grid_y) * warp_magnitude
	var py := grid_y + _noise_warp.get_noise_2d(grid_x + 200, grid_y + 200) * warp_magnitude
	return {
		altura = _noise_altura.get_noise_2d(px, py),
		detalhe = _noise_detalhe.get_noise_2d(grid_x, grid_y),
		vale = 1.0 - absf(_noise_vale.get_noise_2d(px, py)),
		minerio = _noise_minerios.get_noise_2d(grid_x, grid_y),
		bioma = _noise_bioma.get_noise_2d(grid_x, grid_y),
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
			solo.set_cell(pos, FONTE_SOLO, tile_substituto)

func _descarregar_chunk(chunk_pos: Vector2i) -> void:
	var start_x := chunk_pos.x * chunk_tamanho
	var end_x := mini(start_x + chunk_tamanho, largura)
	var start_y := chunk_pos.y * chunk_tamanho
	var end_y := mini(start_y + chunk_tamanho, altura)
	for gx in range(start_x, end_x):
		for gy in range(start_y, end_y):
			var tile_pos := Vector2i(gx + _deslocamento.x, gy + _deslocamento.y)
			solo.set_cell(tile_pos, -1)
			cristais.set_cell(tile_pos, -1)
