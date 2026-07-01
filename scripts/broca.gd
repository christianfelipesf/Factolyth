extends StaticBody2D

var esta_posicionando := true  # Começa no modo de posicionamento
@onready var colisao: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	modulate.a = 0.6
	colisao.disabled = true

func _process(_delta: float) -> void:
	if esta_posicionando:
		# Segue o mouse alinhando no Grid de 32x32
		var posicao_mouse = get_global_mouse_position()
		var grid_x = floor(posicao_mouse.x / 32.0) * 32.0
		var grid_y = floor(posicao_mouse.y / 32.0) * 32.0
		
		global_position = Vector2(grid_x + 16, grid_y + 16)

# Usar _unhandled_input evita que o clique que CRIOU a broca também a FIXE no mesmo frame
func _unhandled_input(event: InputEvent) -> void:
	if esta_posicionando and event.is_action_pressed("instanciar_broca"):
		_colocar_objeto()
		# Avisa o Godot que esse clique já foi usado e não deve passar para outros scripts
		get_viewport().set_input_as_handled()

func _colocar_objeto() -> void:
	esta_posicionando = false
	modulate.a = 1.0       
	colisao.disabled = false
