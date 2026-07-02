extends StaticBody2D

const BRONZE = preload("res://scenes/itens/bronze.tscn")

# 💡 Velocidade de produção configurável pelo Inspetor (em segundos)
@export var tempo_producao : float = 2.0

var esta_posicionando := false
var is_preview := false

# Guardamos uma referência para a esteira atual onde a broca vai descarregar
var esteira_atual: Node2D = null

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $Detector
@onready var timer_producao: Timer = $TimerProducao # 💡 Referência ao Timer

func _ready() -> void:
	if is_preview:
		return

	modulate.a = 1.0
	colisao.disabled = false

	# Configura o tempo do Timer com base na nossa variável exportada
	timer_producao.wait_time = tempo_producao
	# Conecta o sinal de timeout do Timer à função de spawn
	timer_producao.timeout.connect(_on_timer_producao_timeout)

	print("Broca criada!")

	# Espera um frame para o Area2D atualizar as colisões
	await get_tree().physics_frame
	verificar_esteira()


func verificar_esteira():
	for corpo in detector.get_overlapping_bodies():
		if corpo == self:
			continue

		if corpo.is_in_group("esteira"):
			print("✅ Esteira encontrada no início!")
			iniciar_producao(corpo)
			return

	print("❌ Nenhuma esteira encontrada no início.")


# 💡 Nova função para ligar o Timer ao detectar a esteira
func iniciar_producao(esteira: Node2D):
	esteira_atual = esteira
	if timer_producao.is_stopped():
		timer_producao.start()
		print("🏭 Produção iniciada. Ciclo de:", tempo_producao, "segundos.")


# 💡 Nova função para parar o Timer se a esteira sumir
func parar_producao():
	esteira_atual = null
	timer_producao.stop()
	print("🛑 Produção parada (sem esteira).")


func spawnar_bronze(esteira: Node2D):
	if esteira == null:
		return
		
	var bronze = BRONZE.instantiate()
	get_parent().add_child(bronze)

	# Coloca o minério exatamente na esteira
	bronze.global_position = esteira.global_position
	print("🪨 Bronze criado em:", bronze.global_position)


# 💡 Chamado automaticamente toda vez que o Timer zera
# Chamado automaticamente toda vez que o Timer zera
func _on_timer_producao_timeout() -> void:
	if esteira_atual != null:
		# 💡 Checa se já tem algum item na área de spawn antes de criar outro
		var espaco_ocupado := false
		for corpo in detector.get_overlapping_bodies():
			if corpo.is_in_group("item"):
				espaco_ocupado = true
				break
		
		if not espaco_ocupado:
			spawnar_bronze(esteira_atual)
		else:
			print("⏳ Saída bloqueada! Aguardando o item se mover.")


func _on_detector_body_entered(body: Node2D) -> void:
	if body == self:
		return

	if body.is_in_group("esteira"):
		print("✅ Esteira entrou no alcance!")
		iniciar_producao(body)


func _on_detector_body_exited(body: Node2D) -> void:
	if body == self:
		return

	# Se a esteira que saiu era a que estávamos usando, paramos a produção
	if body == esteira_atual:
		print("❌ Esteira saiu do alcance!")
		parar_producao()
