extends StaticBody2D

const VELOCIDADE := 100.0

var is_preview := false
var direcao_atual := 0

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var detector_entrada: Area2D = $DetectorEntrada

func _ready() -> void:
	if is_preview:
		return
	modulate.a = 1.0
	colisao.disabled = false
	detector_entrada.collision_mask = 1
	detector_entrada.body_exited.connect(_on_item_saiu)
	process_priority = 10

func _on_item_saiu(body: Node2D) -> void:
	var chave = _chave_meta()
	if body.has_meta(chave):
		body.set_meta(chave, null)

func _chave_meta() -> String:
	return "distribuidor_%d" % get_instance_id()

func _physics_process(_delta: float) -> void:
	for body in detector_entrada.get_overlapping_bodies():
		if not body.is_in_group("item"):
			continue
		var chave = _chave_meta()
		if body.has_meta(chave) and body.get_meta(chave):
			continue
		var direcoes = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
		var direcao = direcoes[direcao_atual].rotated(global_rotation)
		body.global_position = global_position + direcao * 16
		body.impulso = direcao * VELOCIDADE
		body.esteira_atual_pos = global_position + direcao * 16
		body.set_meta(chave, true)
		direcao_atual = (direcao_atual + 1) % 3
		break