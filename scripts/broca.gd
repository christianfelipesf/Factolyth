extends StaticBody2D

const ITEM = preload("res://scenes/itens/itens.tscn")
const PADRAO = preload("res://resources/itens/quartzo.tres")

@export var tempo_producao: float = 2.0
@export var item_data: ItemData

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
	timer_producao.wait_time = tempo_producao
	timer_producao.timeout.connect(_on_timer_producao_timeout)
	detector.body_entered.connect(_on_detector_body_entered)
	detector.body_exited.connect(_on_detector_body_exited)
	await get_tree().physics_frame
	timer_producao.start()

func _procurar_esteira_no_chao() -> Node2D:
	for corpo in detector.get_overlapping_bodies():
		if corpo == self: continue
		if corpo.is_in_group("esteira"):
			return corpo
		elif corpo.get_parent() and corpo.get_parent().is_in_group("esteira"):
			return corpo.get_parent()
	for area_no in detector.get_overlapping_areas():
		if area_no == self or area_no == detector: continue
		if area_no.is_in_group("esteira"):
			return area_no
		elif area_no.get_parent() and area_no.get_parent().is_in_group("esteira"):
			return area_no.get_parent()
	return null

func _on_timer_producao_timeout() -> void:
	esteira_atual = _procurar_esteira_no_chao()
	if esteira_atual == null:
		return
	var espaco_ocupado := false
	for corpo in detector.get_overlapping_bodies():
		if corpo.is_in_group("item"):
			espaco_ocupado = true
			break
	if not espaco_ocupado:
		_spawnar_item(esteira_atual)

func _spawnar_item(esteira: Node2D) -> void:
	var dados = item_data if item_data != null else PADRAO
	var item = ITEM.instantiate()
	item.inicializar(dados)
	item.global_position = esteira.global_position
	get_parent().call_deferred(&"add_child", item)

func _on_detector_body_entered(body: Node2D) -> void:
	var esteira = _extrair_esteira(body)
	if esteira != null:
		esteira_atual = esteira
		_on_timer_producao_timeout()

func _on_detector_body_exited(body: Node2D) -> void:
	var esteira = _extrair_esteira(body)
	if esteira != null and esteira == esteira_atual:
		esteira_atual = null

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