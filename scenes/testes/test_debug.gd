extends Node2D

var frames := 0
var ultimas_posicoes := {}

func _ready() -> void:
	prints("=== TESTE ESTEIRA INICIADO ===")
	prints("Configuracao:")
	for child in get_children():
		prints(" ", child.name, "em", child.position)

func _physics_process(_delta: float) -> void:
	frames += 1
	for item in get_tree().get_nodes_in_group("item"):
		var pos = item.global_position
		var vel = item.velocidade
		var imp = item.impulso
		var esteira_pos = item.esteira_atual_pos
		var id = item.get_instance_id()

		if id in ultimas_posicoes:
			var ultima = ultimas_posicoes[id]
			var dist = pos.distance_to(ultima)
			if frames <= 10 or frames % 30 == 0 or dist < 0.1:
				prints("F%d item[%s] pos=(%.1f,%.1f) vel=(%.2f,%.2f) imp=(%.2f,%.2f) esteira_pos=(%.1f,%.1f) dist=%.2f" % [frames, item.tipo, pos.x, pos.y, vel.x, vel.y, imp.x, imp.y, esteira_pos.x, esteira_pos.y, dist])
				if dist < 0.1:
					prints(">>> ITEM PARADO! frames:", frames)
		else:
			prints("F%d item[%s] SPAWN pos=(%.1f,%.1f) vel=(%.2f,%.2f) imp=(%.2f,%.2f)" % [frames, item.tipo, pos.x, pos.y, vel.x, vel.y, imp.x, imp.y])

		ultimas_posicoes[id] = pos

	if frames > 120 or frames >= 900:
		prints("=== TESTE CONCLUIDO ===")
		get_tree().quit()
