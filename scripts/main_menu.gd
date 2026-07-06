extends Control

@onready var btn_carregar: Button = $VBoxContainer/Carregar
@onready var btn_deletar: Button = $VBoxContainer/DeletarSaves
@onready var btn_novo_jogo: Button = $VBoxContainer/NovoJogo

@onready var submenu: Control = $SubmenuNovoJogo
@onready var btn_normal: Button = $SubmenuNovoJogo/Normal
@onready var btn_procedural: Button = $SubmenuNovoJogo/Procedural
@onready var btn_voltar: Button = $SubmenuNovoJogo/Voltar


func _ready() -> void:
	_verificar_saves()
	submenu.hide()
	btn_novo_jogo.grab_focus()


func _verificar_saves() -> void:
	var dir := DirAccess.open("user://saves/")
	var tem_save := false
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".json"):
				tem_save = true
				break
			f = dir.get_next()
		dir.list_dir_end()
	btn_carregar.disabled = not tem_save

func _mostrar_submenu() -> void:
	$VBoxContainer.hide()
	submenu.show()
	btn_normal.grab_focus()

func _esconder_submenu() -> void:
	submenu.hide()
	$VBoxContainer.show()
	btn_novo_jogo.grab_focus()

func _on_novo_jogo_pressed() -> void:
	AudioManager.play_click()
	_mostrar_submenu()

func _on_normal_pressed() -> void:
	AudioManager.play_click()
	SaveManager.modo_procedural = false
	SaveManager.modo_jogo = SaveManager.MODO_CRIATIVO
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_procedural_pressed() -> void:
	AudioManager.play_click()
	SaveManager.modo_procedural = false
	SaveManager.modo_jogo = SaveManager.MODO_SOBREVIVENCIA
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_voltar_pressed() -> void:
	AudioManager.play_click()
	_esconder_submenu()

func _on_carregar_pressed() -> void:
	AudioManager.play_click()
	SaveManager.modo_procedural = false
	SaveManager.save_pendente = SaveManager.SLOT_PADRAO
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_deletar_saves_pressed() -> void:
	AudioManager.play_click()
	SaveManager.deletar_todos_saves()
	_verificar_saves()

func _on_sair_pressed() -> void:
	AudioManager.play_click()
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if submenu.visible:
			_on_voltar_pressed()
			_input_handled()
	if event is InputEventJoypadButton and event.pressed \
		and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_X]:
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.pressed.emit()
			_input_handled()


func _input_handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()
