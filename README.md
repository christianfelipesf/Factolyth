# Factolyth

> Um jogo de automação modular e tower defense desenvolvido na Godot Engine.

---

## Sobre o jogo

Um mini robô orgânico usa um teleportador quântico que o leva para um planeta desconhecido. Você começa sem nenhum recurso avançado e precisa minerar veios de quartzo manualmente, processar materiais, criar ligas purificadas e erguer uma linha de automação industrial e defesas para construir um novo teleportador e voltar para casa.

---

## Características

- **Automação e Tower Defense** — Construa esteiras, extratores, fusores e torres automatizadas enquanto enfrenta inimigos.
- **Cadeia de Refino Complexa** — Transforme matéria-prima bruta através de processos de crafting manual e fundição automatizada.
- **Geração procedural** — Mapas gerados proceduralmente com FastNoiseLite, cache em PackedFloat32Array.
- **Sistema de Save/Load** — Salva semente, estruturas, jogador (posição/rotação/zoom/item) com tela de loading.
- **Barra de Seleção** — Interface inferior para selecionar itens com suporte a teclas 1-4, clique, e sincronizada via signals.
- **Controles** — Teclado, mouse, tela sensível ao toque (joystick virtual) e controle (analógico direito para cursor, A/B para ações).
- **Som** — Som ambiente em loop, SFX de colocar/destruir estruturas, partículas ao interagir.
- **Preview de Construção** — Indicador visual com snap ao grid, rotação (R), preview semi-transparente, detecção de área ocupada.

---

## Fluxo de Produção e Progressão

A jornada do jogador é dividida em etapas de processamento e manufatura de componentes:
[Veio de Quartzo (Manual)] ➔ Pó de Quartzo
⬇ (Crafting Manual: 4 Pós = 1 Placa)
[Placa de Quartzo] ➔ Componente de Estruturas (Extrator / Broca)
⬇ (Construção: Requer 2 Placas)
[Extrator de Areia] ➔ Areia Purificada
⬇ + [Pó de Quartzo] (Alimentados no Fusor)
[Fusor] ➔ Silício
⬇ + [1 Placa de Quartzo] (Combinação para Construção)
[Broca Avançada] ➔ Automatiza a extração de minérios em massa dos veios

---

## Controles

| Ação | Teclado | Mouse | Controle | Touch |
|---|---|---|---|---|
| Mover | WASD | — | Analógico esquerdo | Joystick virtual |
| Colocar estrutura | — | Clique Esquerdo | Botão A (Xbox) | Toque no mundo |
| Remover estrutura | — | Clique Direito | Botão B (Xbox) | — |
| Ciclar item | E | — | — | — |
| Selecionar item (1-4) | 1-4 | Clique na barra | — | Toque na barra |
| Cancelar | 0 | — | — | — |
| Rotacionar | R | — | — | — |
| Zoom | — | Scroll | Pinça (2 dedos) | Pinça |
| Salvar | F5 | — | — | — |
| Carregar | F9 | — | — | — |
| Mover cursor | — | Mouse | Analógico direito | Toque |

---

## Elementos do Jogo

### Recursos e Itens (`scenes/itens/`)

| Item | Origem | Descrição / Uso |
|---|---|---|
| **Pó de Quartzo** | Extração Manual | Coletado diretamente pelo jogador ao minerar veios de quartzo pelo mapa. Base de toda a cadeia. |
| **Placa de Quartzo** | Crafting Manual | Fabricado pelo jogador combinando **4 Pós de Quartzo**. Usado para criar estruturas. |
| **Areia Purificada** | Extrator de Areia | Gerada automaticamente pelo Extrator. Insumo essencial para fundição. |
| **Silício** | Fusor | Produto final obtido da fundição de **1 Areia Purificada + 1 Pó de Quartzo**. Usado em tecnologias avançadas. |
| **Quartzo Alvo** | Cristal | Cristal branco básico e abundante, essencial para estruturas de energia iniciais. |
| **Rubelita** | Cristal | Cristal rosa intermediário com propriedades de refração para tecnologias avançadas. |
| **Turmalina-Ciano** | Cristal | Cristal ciano raro e altamente energético, usado para alimentar sistemas complexos. |

### Estruturas Construíveis (`scenes/posicionaveis/`)

| Estrutura | Custo de Construção | Função |
|---|---|---|
| **Extrator de Areia** | 2x Placa de Quartzo | Extrai e injeta automaticamente Areia Purificada nas esteiras adjacentes. |
| **Fusor** | Recursos de Quartzo / Silício | Recebe insumos por esteiras, processa misturas (Areia + Pó) e expele Silício purificado. |
| **Esteira** | Recursos Básicos | Transporta mecanicamente itens e cristais entre estruturas e depósitos. |
| **Broca Avançada** | 1x Silício + 1x Placa de Quartzo | Estrutura automatizada de mineração em massa para veios e cristais no solo. |
| **Canhão** | Recursos Avançados | Torre defensiva de combate automático contra hordas de inimigos. |
| **Núcleo** | Estrutura Inicial | Coleta os cristais e recursos finais que chegam por esteiras para o inventário central de vitória. |

---

## Tecnologias

- **Engine:** Godot 4.7
- **Linguagem:** GDScript
- **Resolução:** 1280×720, stretch `canvas_items` + `keep`
- **Input:** `emulate_touch_from_mouse = true`

---

## Como jogar

1. Clone o repositório.
2. Abra o projeto na Godot Engine 4.7+.
3. Execute a cena principal (`scenes/mundo.tscn`).

---

## Estrutura do Projeto

| Diretório | Finalidade |
|---|---|
| `scripts/` | Código-fonte GDScript e Shaders |
| `scenes/` | Cenas Godot (.tscn) principais |
| `scenes/posicionaveis/` | Estruturas construíveis (broca, esteira, extrator, fusor) |
| `scenes/itens/` | Itens, pós, placas e cristais transportáveis |
| `scenes/particles/` | Efeitos visuais e de partícula |
| `recurso/` | Resources customizados (`ItemConstrucao.gd`) |
| `sound/` | Áudio (música ambiente, efeitos de clique e destruição) |
| `images/` | Sprites, texturas e tilesets visuais |

---

## Licença

Distribuído sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais informações.
