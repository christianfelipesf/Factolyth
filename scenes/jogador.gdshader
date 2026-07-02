shader_type canvas_item;

// Uniforms configuráveis diretamente pelo Inspector do Godot
uniform vec2 deslocamento = vec2(0.0, 3.0); // Deslocamento da sombra em pixels (X, Y)
uniform vec4 cor_sombra : source_color = vec4(0.0, 0.0, 0.0, 0.4); // Cor preta com 40% de opacidade

void vertex() {
	// Mantido padrão para processamento de vértices básico
}

void fragment() {
	// Obtém a cor e opacidade do pixel original do jogador
	vec4 cor_original = texture(TEXTURE, UV);
	
	// Calcula a coordenada UV de onde a sombra será projetada
	// Multiplicamos pelo TEXTURE_PIXEL_SIZE para que o deslocamento seja baseado em pixels reais
	vec2 uv_sombra = UV - (deslocamento * TEXTURE_PIXEL_SIZE);
	
	// Verifica se a coordenada calculada está dentro dos limites da textura (0.0 a 1.0)
	if (uv_sombra.x >= 0.0 && uv_sombra.x <= 1.0 && uv_sombra.y >= 0.0 && uv_sombra.y <= 1.0) {
		vec4 amostra_sombra = texture(TEXTURE, uv_sombra);
		
		// Se o pixel atual for transparente e o pixel deslocado for opaco, desenha a sombra
		if (cor_original.a < 0.1 && amostra_sombra.a > 0.1) {
			cor_original = cor_sombra;
		}
	}
	
	// Define a cor final do pixel
	COLOR = cor_original;
}