extends TextureButton

const CLIQUE = preload("res://sound/click.mp3")
const TEXTURA_COLOCAR = preload("res://images/ui/colocar_bloco.png")
const TEXTURA_RETIRAR = preload("res://images/ui/retirar_bloco.png")

var _audio_click: AudioStreamPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_audio_click = AudioStreamPlayer.new()
	_audio_click.stream = CLIQUE
	add_child(_audio_click)
	pressed.connect(_on_pressed)
	atualizar_textura()


func _on_pressed() -> void:
	_clicar()
	var cursor = get_tree().root.find_child("Marker2D", true, false)
	if cursor != null and cursor.has_method("alternar_modo_destruir"):
		cursor.alternar_modo_destruir()
	atualizar_textura()


func _clicar() -> void:
	_audio_click.play()


func atualizar_textura() -> void:
	var cursor = get_tree().root.find_child("Marker2D", true, false)
	if cursor != null and cursor.has_method("tem_modo_destruir"):
		texture_normal = TEXTURA_RETIRAR if cursor.tem_modo_destruir() else TEXTURA_COLOCAR
