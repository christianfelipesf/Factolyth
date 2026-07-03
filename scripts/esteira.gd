extends StaticBody2D

var is_preview := false

@export var VELOCIDADE := 100.0

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var area: Area2D = $Area2D

func _ready() -> void:
	if is_preview:
		set_process(false)
		set_physics_process(false)
		return

	modulate.a = 1.0
	colisao.disabled = false

func _physics_process(_delta: float) -> void:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("item"):
			body.impulso = Vector2.UP.rotated(global_rotation) * VELOCIDADE
			body.esteira_atual_pos = global_position
