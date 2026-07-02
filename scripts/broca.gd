extends StaticBody2D

const BRONZE = preload("res://scenes/itens/itens.tscn")

# 💡 Velocidade de produção configurável pelo Inspetor (em segundos)
@export var tempo_producao : float = 2.0

var is_preview := false
var esteira_atual: Node2D = null

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $Detector
@onready var timer_producao: Timer = $TimerProducao 

func _ready() -> void:
	if is_preview:
		return

	modulate.a = 1.0
	colisao.disabled = false

	# O timer vai rodar em loop constante cuidando da vida da broca
	timer_producao.wait_time = tempo_producao
	timer_producao.timeout.connect(_on_timer_producao_timeout)
	
	print("Broca criada!")

	detector.body_entered.connect(_on_detector_body_entered)
	detector.body_exited.connect(_on_detector_body_exited)

	# Espera o mapa carregar e liga o ciclo autônomo
	await get_tree().physics_frame
	timer_producao.start()


# 🌟 ESCÂNER REFORÇADO: Descobre se tem uma esteira debaixo da broca
func _procurar_esteira_no_chao() -> Node2D:
	# 1. Procura nos corpos físicos (StaticBody2D)
	for corpo in detector.get_overlapping_bodies():
		if corpo == self: continue
		if corpo.is_in_group("esteira"):
			return corpo
		elif corpo.get_parent() and corpo.get_parent().is_in_group("esteira"):
			return corpo.get_parent()
			
	# 2. Procura em nós de Área (Area2D)
	for area_no in detector.get_overlapping_areas():
		if area_no == self or area_no == detector: continue
		if area_no.is_in_group("esteira"):
			return area_no
		elif area_no.get_parent() and area_no.get_parent().is_in_group("esteira"):
			return area_no.get_parent()
			
	return null


# 💡 Ciclo autônomo acionado a cada 'X' segundos pelo Timer
func _on_timer_producao_timeout() -> void:
	# 1. A broca pesquisa o chão ativamente neste exato milissegundo
	esteira_atual = _procurar_esteira_no_chao()
	
	# 2. Se não achou nada, ela apenas avisa e espera o próximo ciclo do timer
	if esteira_atual == null:
		print("🛑 Broca em espera: Nenhuma esteira detectada sob o minerador.")
		return 
		
	# 3. Se achou, ela tenta trabalhar! Checa se a saída está limpa
	var espaco_ocupado := false
	for corpo in detector.get_overlapping_bodies():
		if corpo.is_in_group("item"):
			espaco_ocupado = true
			break
	
	if not espaco_ocupado:
		_spawnar_bronze(esteira_atual)
	else:
		print("⏳ Saída da broca bloqueada por um minério! Aguardando mover.")


func _spawnar_bronze(esteira: Node2D) -> void:
	var bronze = BRONZE.instantiate()
	
	# Nasce de dentro da broca sem glitch
	bronze.global_position = global_position
	get_parent().add_child(bronze)

	# Posiciona na esteira alvo
	bronze.global_position = esteira.global_position
	print("🏭 [PRODUÇÃO] Bronze extraído com sucesso para a esteira!")

func _on_detector_body_entered(body: Node2D) -> void:
	var esteira = _extrair_esteira(body)
	if esteira != null:
		esteira_atual = esteira
		_on_timer_producao_timeout()

func _on_detector_body_exited(body: Node2D) -> void:
	var esteira = _extrair_esteira(body)
	if esteira != null and esteira == esteira_atual:
		esteira_atual = null
		print("🛑 Broca: Esteira removida. Aguardando nova esteira.")

func _extrair_esteira(body: Node2D) -> Node2D:
	if body == self:
		return null
	if body.is_in_group("esteira"):
		return body
	if body.get_parent() and body.get_parent().is_in_group("esteira"):
		return body.get_parent()
	return null

func verificar_extrutura_e_atualizar_estado() -> void:
	esteira_atual = _procurar_esteira_no_chao()
