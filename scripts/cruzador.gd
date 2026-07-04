extends StaticBody2D

const VELOCIDADE := 100.0

var is_preview := false

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $Detector

func _ready() -> void:
	if is_preview:
		return
	modulate.a = 1.0
	colisao.disabled = false
	detector.collision_mask = 1
	process_priority = 10

func _physics_process(_delta: float) -> void:
	for body in detector.get_overlapping_bodies():
		if not body.is_in_group("item"):
			continue
		var chave = "cruzador_%d" % get_instance_id()
		if body.has_meta(chave) and body.get_meta(chave):
			continue

		var pos_local = to_local(body.global_position)
		var direcao: Vector2

		if absf(pos_local.x) > absf(pos_local.y):
			direcao = Vector2.RIGHT if pos_local.x < 0 else Vector2.LEFT
		else:
			direcao = Vector2.DOWN if pos_local.y < 0 else Vector2.UP

		direcao = direcao.rotated(global_rotation)
		body.global_position = global_position + direcao * 16
		body.impulso = direcao * VELOCIDADE
		body.esteira_atual_pos = global_position + direcao * 16
		body.set_meta(chave, true)
		break