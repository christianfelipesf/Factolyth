extends StaticBody2D

const TAMANHO_GRID: Vector2i = Vector2i(2, 2)

var is_preview := false

# 📊 Dicionário para guardar o tipo de item e a quantidade armazenada
var inventario := {
	"quartzo": 0,
}

signal inventario_atualizado(inv: Dictionary)

@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var coletor: Area2D = $Coletor

func _ready() -> void:
	if is_preview:
		set_process(false)
		set_physics_process(false)
		return

	modulate.a = 1.0
	colisao.disabled = false
	
	# 🔗 Conecta o sinal de entrada de corpos do Coletor via código
	coletor.body_entered.connect(_on_coletor_body_entered)

func _on_coletor_body_entered(body: Node2D) -> void:
	if body.is_in_group("item"):
		# 💡 Identifica qual é o minério. 
		# Se você não tiver uma variável 'nome_do_item' no item, podemos usar o nome do nó ou grupo.
		# Exemplo assumindo que o script do item possui uma variável identificadora ou usando o nome do objeto:
		var tipo_item = "quartzo" 
		
		# Se o seu script do item tiver uma variável para diferenciar (ex: var tipo = "bronze")
		if body.get("tipo") != null:
			tipo_item = body.tipo
		
		# 📈 Guarda a quantidade no dicionário
		if inventario.has(tipo_item):
			inventario[tipo_item] += 1
		else:
			inventario[tipo_item] = 1
			
		print("📥 Item absorvido pelo Núcleo! Estoque atual de ", tipo_item, ": ", inventario[tipo_item])
		inventario_atualizado.emit(inventario)

		# 💥 Faz o item ir "para dentro dele" (deleta o objeto do mapa com segurança)
		body.queue_free()

func get_save_data() -> Dictionary:
	return {inventario = inventario.duplicate()}

func set_save_data(dados: Dictionary) -> void:
	if dados.has("inventario"):
		inventario = dados.inventario.duplicate()
	inventario_atualizado.emit(inventario)
