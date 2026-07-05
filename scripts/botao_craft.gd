extends TextureButton

const CLIQUE = preload("res://sound/click.mp3")

@onready var _crafting_hud: Node = get_parent().find_child("CraftingHUD", true, false)
var _audio_click: AudioStreamPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if _crafting_hud == null:
		push_error("BotaoCraft: CraftingHUD não encontrado")
	_audio_click = AudioStreamPlayer.new()
	_audio_click.stream = CLIQUE
	add_child(_audio_click)


func _clicar() -> void:
	_audio_click.play()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		_clicar()
		if _crafting_hud != null and _crafting_hud.has_method("toggle"):
			_crafting_hud.toggle()