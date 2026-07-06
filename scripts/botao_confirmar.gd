extends TextureButton

const CLIQUE = preload("res://sound/click.mp3")

var _audio_click: AudioStreamPlayer


func _ready() -> void:
	_audio_click = AudioStreamPlayer.new()
	_audio_click.stream = CLIQUE
	add_child(_audio_click)
	pressed.connect(_on_pressed)


func _process(delta: float) -> void:
	var cursor = get_tree().root.find_child("Marker2D", true, false)
	visible = cursor != null and cursor.has_method("tem_pendentes") and cursor.tem_pendentes()


func _on_pressed() -> void:
	_audio_click.play()
	var cursor = get_tree().root.find_child("Marker2D", true, false)
	if cursor != null and cursor.has_method("confirmar_pendentes"):
		cursor.confirmar_pendentes()
