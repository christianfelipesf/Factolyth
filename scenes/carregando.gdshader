shader_type canvas_item;

// Parâmetros customizáveis no Inspector
uniform vec4 cor_nuvem : source_color = vec4(0.0, 0.0, 0.0, 1.0);       // Cor das nuvens (Preto)
uniform vec4 cor_fundo : source_color = vec4(0.0, 0.0, 0.0, 1.0);       // Cor do fundo geral (Preto)
uniform float transparencia_fundo : hint_range(0.0, 1.0) = 0.5;         // Opacidade do fundo (0 = Invisível, 1 = Totalmente opaco)

uniform float velocidade : hint_range(0.0, 0.5) = 0.02;
uniform float escala_ruido : hint_range(1.0, 20.0) = 4.0;
uniform float densidade : hint_range(0.0, 1.0) = 0.5;

// Função matemática para gerar ruído procedural (fBm)
float gerar_ruido(vec2 uv) {
	return fract(sin(dot(uv, vec3(12.9898, 78.233, 45.164).xy)) * 43758.5453);
}

float interpolar_ruido(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = gerar_ruido(i);
	float b = gerar_ruido(i + vec2(0.0, 1.0));
	
	return mix(mix(a, gerar_ruido(i + vec2(1.0, 0.0)), f.x), mix(b, gerar_ruido(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 uv) {
	float valor = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		valor += amplitude * interpolar_ruido(uv);
		uv *= 2.0;
		amplitude *= 0.5;
	}
	return valor;
}

void fragment() {
	// Movimenta o UV baseado no tempo para o efeito de vento
	vec2 uv_movimentado = UV * escala_ruido + TIME * velocidade;
	
	// Gera a textura da nuvem (valor de 0.0 a 1.0)
	float valor_ruido = fbm(uv_movimentado);
	
	// Controla onde a nuvem aparece com base na densidade
	float mascara_nuvem = smoothstep(densidade, densidade + 0.3, valor_ruido);
	
	// Define a opacidade final do fundo (aplicando o slider de transparência)
	vec4 fundo_final = vec4(cor_fundo.rgb, cor_fundo.a * transparencia_fundo);
	
	// Define a nuvem final (usando a cor preta escolhida)
	vec4 nuvem_final = cor_nuvem;
	
	// Mistura o fundo transparente com a nuvem opaca baseando-se na máscara do ruído
	COLOR = mix(fundo_final, nuvem_final, mascara_nuvem);
}