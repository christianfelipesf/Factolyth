extends StaticBody2D

const TAMANHO_GRID: Vector2i = Vector2i(1, 1)
const ITEM = preload("res://scenes/itens/itens.tscn")

const MAX_AREIA := 2
const MAX_QUARTZO := 1

var is_preview := false
var estoque_areia := 0
var estoque_quartzo := 0
var produzindo := false

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var coletor: Area2D = $Coletor
@onready var timer_producao: Timer = $TimerProducao

func _ready() -> void:
	if is_preview:
		return
	modulate.a = 1.0
	colisao.disabled = false
	coletor.body_entered.connect(_on_coletor_body_entered)
	timer_producao.timeout.connect(_produzir)

func _on_coletor_body_entered(body: Node2D) -> void:
	if not body.is_in_group("item"):
		return
	if produzindo:
		return
	var tipo = body.get("tipo") if "tipo" in body else ""
	if tipo == "areia" and estoque_areia < MAX_AREIA:
		estoque_areia += 1
		body.queue_free()
		_verificar_producao()
	elif tipo == "quartzo" and estoque_quartzo < MAX_QUARTZO:
		estoque_quartzo += 1
		body.queue_free()
		_verificar_producao()

func _verificar_producao() -> void:
	if produzindo:
		return
	if estoque_areia >= MAX_AREIA and estoque_quartzo >= MAX_QUARTZO:
		produzindo = true
		timer_producao.start()

func _procurar_esteira_acima() -> Node2D:
	var espaco = 16
	var direcao = Vector2.UP.rotated(global_rotation)
	var centro = global_position + direcao * 32
	var espaco_superior = PhysicsShapeQueryParameters2D.new()
	espaco_superior.shape = RectangleShape2D.new()
	espaco_superior.shape.size = Vector2(28, 28)
	espaco_superior.transform = Transform2D(0, centro)
	espaco_superior.collision_mask = 1
	var resultado = get_world_2d().direct_space_state.intersect_shape(espaco_superior)
	for r in resultado:
		var obj = r.collider
		if obj == self: continue
		if obj.is_in_group("esteira"):
			return obj
		if obj.get_parent() and obj.get_parent().is_in_group("esteira"):
			return obj.get_parent()
	return null

func _produzir() -> void:
	estoque_areia -= MAX_AREIA
	estoque_quartzo -= MAX_QUARTZO
	produzindo = false
	var esteira = _procurar_esteira_acima()
	if esteira == null:
		return
	var dados = ItemRegistry.get_item("silicio")
	if dados == null:
		return
	var item = ITEM.instantiate()
	item.inicializar(dados)
	item.global_position = esteira.global_position
	get_parent().call_deferred(&"add_child", item)

func get_save_data() -> Dictionary:
	return {
		areia = estoque_areia,
		quartzo = estoque_quartzo,
		produzindo = produzindo,
	}

func set_save_data(dados: Dictionary) -> void:
	estoque_areia = dados.get("areia", 0)
	estoque_quartzo = dados.get("quartzo", 0)
	produzindo = dados.get("produzindo", false)
	if produzindo and timer_producao != null:
		timer_producao.start()
