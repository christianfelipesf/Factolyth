extends TextureButton

const CLIQUE = preload("res://sound/click.mp3")
const DURACAO_GIRO := 0.15

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
		_animar_rotacao()


func _animar_rotacao() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", rotation + deg_to_rad(90.0), DURACAO_GIRO)
