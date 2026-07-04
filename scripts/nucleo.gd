extends StaticBody2D

const TAMANHO_GRID: Vector2i = Vector2i(2, 2)

var is_preview := false

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var coletor: Area2D = $Coletor

func _ready() -> void:
	if is_preview:
		set_process(false)
		set_physics_process(false)
		return
	modulate.a = 1.0
	colisao.disabled = false
	coletor.body_entered.connect(_on_coletor_body_entered)

func _on_coletor_body_entered(body: Node2D) -> void:
	if not body.is_in_group("item"):
		return
	var tipo_item = body.tipo if body.get("tipo") != null else "quartzo"
	var jogador = get_node_or_null("/root/Mundo/Jogador")
	if jogador != null and jogador.has_method("adicionar_item"):
		jogador.adicionar_item(tipo_item)
	body.queue_free()

func get_save_data() -> Dictionary:
	return {}

func set_save_data(_dados: Dictionary) -> void:
	pass