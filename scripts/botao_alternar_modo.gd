extends TextureButton

const CLIQUE = preload("res://sound/click.mp3")

@export var texture_normal_colocar: Texture2D
@export var texture_normal_retirar: Texture2D

var _audio_click: AudioStreamPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_audio_click = AudioStreamPlayer.new()
	_audio_click.stream = CLIQUE
	add_child(_audio_click)
	atualizar_textura()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
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
		texture_normal = texture_normal_retirar if cursor.tem_modo_destruir() else texture_normal_colocar