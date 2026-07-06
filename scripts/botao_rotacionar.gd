extends TextureButton

const CLIQUE = preload("res://sound/click.mp3")

var _audio_click: AudioStreamPlayer


func _ready() -> void:
	_audio_click = AudioStreamPlayer.new()
	_audio_click.stream = CLIQUE
	add_child(_audio_click)
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	_audio_click.play()
	var cursor = get_tree().root.find_child("Marker2D", true, false)
	if cursor != null and cursor.has_method("rotacionar"):
		cursor.rotacionar()
