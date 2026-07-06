extends TextureButton


func _ready() -> void:
	pressed.connect(_on_pressed)


func _process(delta: float) -> void:
	var cursor = get_tree().get_first_node_in_group("cursor")
	visible = cursor != null and cursor.has_method("tem_pendentes") and cursor.tem_pendentes()


func _on_pressed() -> void:
	AudioManager.play_click()
	var cursor = get_tree().get_first_node_in_group("cursor")
	if cursor != null and cursor.has_method("confirmar_pendentes"):
		cursor.confirmar_pendentes()
