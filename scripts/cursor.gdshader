shader_type canvas_item;

// Controles no painel Inspector do Godot
uniform float velocidade_pulsar : hint_range(0.1, 10.0) = 3.0;
uniform float intensidade_pulso : hint_range(0.0, 0.2) = 0.05;
uniform float brilho_borda : hint_range(0.0, 5.0) = 1.5;

void vertex() {
	// 1. Faz o cursor pulsar levemente de tamanho usando uma onda Seno baseada no tempo (TIME)
	// Como a nave se move no espaço, esse pulso dá uma sensação de "alvo ativo"
	float pulso = sin(TIME * velocidade_pulsar) * intensidade_pulso;
	VERTEX += VERTEX * pulso;
}

void fragment() {
	// 2. Pega a cor e o Alpha originais do seu Sprite (mantém a sua arte intacta!)
	vec4 cor_original = texture(TEXTURE, UV);
	
	// 3. Cria um efeito de oscilação de brilho (onda baseada no tempo)
	float onda_brilho = (sin(TIME * velocidade_pulsar * 1.5) + 1.0) / 2.0;
	
	// 4. Aplica o brilho apenas onde o sprite tem cor (multiplicando pelo Alpha original)
	// Isso faz as bordas e os detalhes da sua arte brilharem sem mudar a paleta de cores
	vec3 cor_final = cor_original.rgb + (cor_original.rgb * onda_brilho * brilho_borda);
	
	// Retorna a cor brilhante mantendo a transparência perfeita do Sprite original
	COLOR = vec4(cor_final, cor_original.a);
}