extends CharacterBody2D

var dados: ItemData
var velocidade := Vector2.ZERO
var impulso := Vector2.ZERO
var esteira_atual_pos := Vector2.INF
var tipo := ""
var no_chao := false
var tempo_fora_da_esteira := 0.0
const TEMPO_PARA_DESAPARECER := 3.0

func inicializar(data: ItemData) -> void:
	dados = data
	tipo = data.id
	var sprite := $Sprite2D as Sprite2D
	if sprite:
		sprite.texture = data.textura

func _ready() -> void:
	add_to_group("item")
	collision_layer = 1
	collision_mask = 4
	var shape = $CollisionShape2D.shape as CircleShape2D
	if shape != null:
		shape.radius = 6.0

func _physics_process(delta: float) -> void:
	if impulso != Vector2.ZERO:
		no_chao = false
		tempo_fora_da_esteira = 0.0

		velocidade = impulso

		if esteira_atual_pos != Vector2.INF:
			var direcao_movimento = impulso.normalized()

			if absf(direcao_movimento.x) > 0.5:
				global_position.y = lerp(global_position.y, esteira_atual_pos.y, 0.2)
			elif absf(direcao_movimento.y) > 0.5:
				global_position.x = lerp(global_position.x, esteira_atual_pos.x, 0.2)

	else:
		velocidade = velocidade.lerp(Vector2.ZERO, 0.2)
		esteira_atual_pos = Vector2.INF

		no_chao = true
		tempo_fora_da_esteira += delta

		if tempo_fora_da_esteira >= TEMPO_PARA_DESAPARECER:
			queue_free()

	velocity = velocidade
	move_and_slide()

	impulso = Vector2.ZERO
