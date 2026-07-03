extends Control

@onready var btn_carregar: Button = $VBoxContainer/Carregar
@onready var btn_deletar: Button = $VBoxContainer/DeletarSaves

func _ready() -> void:
	_verificar_saves()

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

func _on_novo_jogo_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_carregar_pressed() -> void:
	# Salva o slot pendente antes de trocar de cena.
	# O SaveManager carregará automaticamente quando a nova cena estiver pronta.
	SaveManager.save_pendente = "slot_1"
	get_tree().change_scene_to_file("res://scenes/mundo.tscn")

func _on_deletar_saves_pressed() -> void:
	SaveManager.deletar_todos_saves()
	_verificar_saves()

func _on_sair_pressed() -> void:
	get_tree().quit()
