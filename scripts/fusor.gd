extends StaticBody2D

const TAMANHO_GRID: Vector2i = Vector2i(1, 1)

var is_preview := false

@onready var colisao: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if is_preview:
		set_process(false)
		set_physics_process(false)
		return
	modulate.a = 1.0
	colisao.disabled = false
