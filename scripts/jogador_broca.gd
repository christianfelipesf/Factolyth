class_name JogadorBrocaModule extends RefCounted

var _jogador: Node
var _cooldown_broca := 0.0


func setup(jogador: Node) -> void:
	_jogador = jogador


func process(delta: float) -> void:
	if _cooldown_broca > 0:
		_cooldown_broca -= delta


func usar_broca_manual(pos: Vector2) -> void:
	if _cooldown_broca > 0:
		return
	_cooldown_broca = 4.0
	_jogador.velocity = Vector2.ZERO
	_jogador.controles_travados = true

	var dir = pos - _jogador.global_position
	var angulo_alvo = dir.angle()

	var tween = _jogador.create_tween()
	tween.tween_property(_jogador, "rotation", angulo_alvo, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(_jogador, "global_position", pos, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_iniciar_giro_broca)


func _iniciar_giro_broca() -> void:
	_jogador.get_node("AudioBrocaManual").play()

	var tween = _jogador.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_jogador, "rotation", _jogador.rotation + deg_to_rad(360.0 * 6), 3.0)
	tween.tween_callback(func():
		_jogador.controles_travados = false
		_jogador.get_node("AudioBrocaManual").stop()
		if SaveManager.modo_jogo == SaveManager.MODO_SOBREVIVENCIA:
			_jogador.adicionar_item("quartzo", 4)
	)


func esta_em_cooldown_broca() -> bool:
	return _cooldown_broca > 0
