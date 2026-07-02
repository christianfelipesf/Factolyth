extends CharacterBody2D

var velocidade := Vector2.ZERO
var impulso := Vector2.ZERO
# Guarda a posição da esteira em que o item está pisando [cite: 40]
var esteira_atual_pos := Vector2.INF 
var tipo := "bronze" # 💡 Adicione isso para o Núcleo saber exatamente o que está guardando
# 💡 Variáveis para controlar o tempo de desaparecer no chão
var no_chao := false
var tempo_fora_da_esteira := 0.0
const TEMPO_PARA_DESAPARECER := 3.0

func _ready() -> void:
	add_to_group("item")
	collision_layer = 5
	collision_mask = 4
	var shape = $CollisionShape2D.shape as CircleShape2D
	if shape != null:
		shape.radius = 6.0

func _physics_process(delta: float) -> void:
	if impulso != Vector2.ZERO:
		# 💡 Se recebeu impulso, ele está na esteira! Reseta o temporizador
		no_chao = false
		tempo_fora_da_esteira = 0.0
		
		velocidade = impulso
		
		# ALINHAMENTO DE CURVA:
		# Se sabemos onde está a esteira, centralizamos o item no eixo oposto ao movimento [cite: 41]
		if esteira_atual_pos != Vector2.INF:
			var direcao_movimento = impulso.normalized()
			
			# Descobre qual eixo está livre (se move em Y, centraliza em X. Se move em X, centraliza em Y) [cite: 41]
			if abs(direcao_movimento.x) > 0.5: # Movendo-se na horizontal
				global_position.y = lerp(global_position.y, esteira_atual_pos.y, 0.2)
			elif abs(direcao_movimento.y) > 0.5: # Movendo-se na vertical
				global_position.x = lerp(global_position.x, esteira_atual_pos.x, 0.2)
				
	else:
		# 💡 Se NÃO recebeu impulso, significa que ele saiu da esteira e caiu no chão!
		velocidade = velocidade.lerp(Vector2.ZERO, 0.2)
		esteira_atual_pos = Vector2.INF # Reseta quando sai das esteiras [cite: 41]
		
		# Inicia ou continua a contagem para sumir
		no_chao = true
		tempo_fora_da_esteira += delta
		
		# Se atingir os 3 segundos acumulados no chão, o item é deletado
		if tempo_fora_da_esteira >= TEMPO_PARA_DESAPARECER:
			queue_free()
	
	velocity = velocidade
	move_and_slide()
	
	# Reseta as forças para o próximo frame 
	impulso = Vector2.ZERO
