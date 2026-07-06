extends Node

const CLIQUE = preload("res://sound/click.mp3")

var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.stream = CLIQUE
	add_child(_player)


func play_click() -> void:
	_player.play()