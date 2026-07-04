extends Node

const CLIQUE = preload("res://sound/click.mp3")

@onready var overlay: ColorRect = $Overlay
@onready var painel: Panel = $Painel
@onready var btn_continuar: Button = $Painel/VBoxContainer/Continuar
@onready var btn_salvar: Button = $Painel/VBoxContainer/Salvar
@onready var btn_carregar: Button = $Painel/VBoxContainer/Carregar
@onready var btn_menu: Button = $Painel/VBoxContainer/MenuPrincipal
@onready var confirmacao: ConfirmationDialog = $Confirmacao

var aberto := false
var _audio_click: AudioStreamPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	overlay.hide()
	painel.hide()
	_audio_click = AudioStreamPlayer.new()
	_audio_click.stream = CLIQUE
	add_child(_audio_click)


func _clicar() -> void:
	_audio_click.play()


func _unhandled_input(event: InputEvent) -> void:
	if _acao_pausa(event):
		if aberto:
			fechar()
		else:
			abrir()
		get_viewport().set_input_as_handled()


func _acao_pausa(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") \
		or event.is_action_pressed("pausa") \
		or _is_start_button(event)


func _is_start_button(event: InputEvent) -> bool:
	return event is InputEventJoypadButton \
		and event.button_index == JOY_BUTTON_START \
		and event.pressed


func abrir() -> void:
	aberto = true
	overlay.show()
	painel.show()
	get_tree().paused = true


func fechar() -> void:
	aberto = false
	overlay.hide()
	painel.hide()
	get_tree().paused = false


func _on_botao_pausa_pressed() -> void:
	if aberto:
		fechar()
	else:
		abrir()

func _on_continuar_pressed() -> void:
	_clicar()
	fechar()


func _on_salvar_pressed() -> void:
	_clicar()
	if SaveManager.modo_procedural:
		var texto_original := btn_salvar.text
		btn_salvar.text = "Indisponível"
		await get_tree().create_timer(0.8).timeout
		btn_salvar.text = texto_original
		return
	SaveManager.salvar("slot_1")
	# Feedback visual: muda texto temporariamente
	var texto_original := btn_salvar.text
	btn_salvar.text = "Salvo!"
	await get_tree().create_timer(0.8).timeout
	btn_salvar.text = texto_original


func _on_carregar_pressed() -> void:
	_clicar()
	# Fecha o menu antes de carregar (esconde overlay + painel, despausa)
	fechar()
	# O SaveManager mostrará a própria tela de carregamento
	SaveManager.carregar("slot_1")


func _on_menu_principal_pressed() -> void:
	_clicar()
	# Mostra confirmação antes de sair
	confirmacao.popup_centered()


func _on_confirmacao_confirmado() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
