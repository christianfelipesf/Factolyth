extends TextureButton

@onready var _pause_menu: Node = get_parent().find_child("PauseMenu", true, false)


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if _pause_menu == null:
		push_error("BotaoPausa: PauseMenu não encontrado")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		AudioManager.play_click()
		if _pause_menu != null and _pause_menu.has_method("_on_botao_pausa_pressed"):
			_pause_menu._on_botao_pausa_pressed()
