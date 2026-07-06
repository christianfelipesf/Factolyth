shader_type canvas_item;

// Captura a tela atrás do objeto
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// --- A TEXTURA DE RUÍDO (Essencial para o efeito orgânico) ---
uniform sampler2D textura_ruido : hint_default_black, repeat_enable;

// --- Controles da Distorção Organica Total ---
uniform float raio_circulo_base : hint_range(0.0, 0.5) = 0.40;   // Raio interno estável
uniform float esfumacado_borda : hint_range(0.01, 0.4) = 0.20; // O quanto a borda embaça
uniform float forca_distorcao_max : hint_range(0.0, 0.5) = 0.25; // Força máxima (na borda)
uniform float forca_distorcao_centro : hint_range(0.0, 0.2) = 0.05; // Distorção base no centro
uniform float velocidade_ruido : hint_range(0.0, 5.0) = 1.2;

// --- Controle de Cor ---
uniform vec4 cor_efeito : source_color = vec4(0.0, 0.7, 1.0, 0.3); // Cor interna (Alpha maior)

void fragment() {
    // 1. Calcular a distância e direção até o centro (0.5, 0.5)
    vec2 centro = vec2(0.5, 0.5);
    float distancia = distance(UV, centro);
    vec2 direcao_afastamento = normalize(UV - centro);
    
    // 2. Amostrar o Ruído para criar a irregularidade (adicionando movimento)
    // Movimento diagonal para parecer mais caótico
    vec2 uv_ruido = UV + vec2(TIME * velocidade_ruido * 0.7, TIME * velocidade_ruido);
    float valor_ruido = texture(textura_ruido, uv_ruido).r;
    
    // 3. Criar a MÁSCARA ORGÂNICA E EMBACADA
    // Define onde o efeito existe e o degradê de transparência na borda.
    float limite_corte = raio_circulo_base + (valor_ruido * esfumacado_borda);
    float mascara_organica = 1.0 - smoothstep(raio_circulo_base - (esfumacado_borda * 2.0), limite_corte, distancia);
    
    // Descarte agressivo fora da zona esfumaçada
    if (mascara_organica <= 0.0) {
        discard;
    }
    
    // 4. Calcular a Distorção Organica TOTAL (Mágica Nova aqui!)
    // Criamos um degradê de força: o centro tem 'forca_distorcao_centro'
    // e ele sobe suavemente até 'forca_distorcao_max' na borda.
    // Usamos smoothstep para a transição interna ser suave.
    float degrade_forca_interna = smoothstep(0.0, raio_circulo_base, distancia);
    float forca_base_interpolada = mix(forca_distorcao_centro, forca_distorcao_max, degrade_forca_interna);
    
    // Agora multiplicamos essa força base pelo ruído para dar o caráter orgânico
    float distorcao_total = forca_base_interpolada * (valor_ruido * 2.0);
    
    // 5. Aplicar a distorção nas coordenadas da tela
    // Usamos a direção para empurrar os pixels de forma radial
    vec2 uv_distorcido = SCREEN_UV + (direcao_afastamento * distorcao_total);
    
    // 6. Pegar a cor de fundo distorcida
    vec4 cor_tela = texture(screen_texture, uv_distorcido);
    
    // 7. Misturar com a cor escolhida e aplicar o degradê orgânico de Alpha
    vec3 cor_final = mix(cor_tela.rgb, cor_efeito.rgb, cor_efeito.a * mascara_organica);
    
    COLOR = vec4(cor_final, cor_tela.a * mascara_organica);
}