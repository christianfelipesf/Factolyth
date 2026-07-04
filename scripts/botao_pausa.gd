extends TextureButton

const CLIQUE = preload("res://sound/click.mp3")

@onready var _pause_menu: Node = get_parent().find_child("PauseMenu", true, false)

var _audio_click: AudioStreamPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if _pause_menu == null:
		push_error("BotaoPausa: PauseMenu não encontrado")
	_audio_click = AudioStreamPlayer.new()
	_audio_click.stream = CLIQUE
	add_child(_audio_click)


func _clicar() -> void:
	_audio_click.play()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		_clicar()
		if _pause_menu != null and _pause_menu.has_method("_on_botao_pausa_pressed"):
			_pause_menu._on_botao_pausa_pressed()
