extends TextureButton

const TEXTURA_COLOCAR = preload("res://images/ui/colocar_bloco.png")
const TEXTURA_RETIRAR = preload("res://images/ui/retirar_bloco.png")


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)
	atualizar_textura()


func _on_pressed() -> void:
	AudioManager.play_click()
	var cursor = get_tree().get_first_node_in_group("cursor")
	if cursor != null and cursor.has_method("alternar_modo_destruir"):
		cursor.alternar_modo_destruir()
	atualizar_textura()


func atualizar_textura() -> void:
	var cursor = get_tree().get_first_node_in_group("cursor")
	if cursor != null and cursor.has_method("tem_modo_destruir"):
		texture_normal = TEXTURA_RETIRAR if cursor.tem_modo_destruir() else TEXTURA_COLOCAR
