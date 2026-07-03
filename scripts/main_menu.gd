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

func _esconder_submenu() -> void:
	submenu.hide()
	$VBoxContainer.show()

func _on_novo_jogo_pressed() -> void:
	_mostrar_submenu()

func _on_normal_pressed() -> void:
	SaveManager.modo_procedural = false
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_procedural_pressed() -> void:
	SaveManager.modo_procedural = true
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_voltar_pressed() -> void:
	_esconder_submenu()

func _on_carregar_pressed() -> void:
	SaveManager.modo_procedural = false
	SaveManager.save_pendente = "slot_1"
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_deletar_saves_pressed() -> void:
	SaveManager.deletar_todos_saves()
	_verificar_saves()

func _on_sair_pressed() -> void:
	get_tree().quit()
