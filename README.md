# Factolyth

> Um jogo de automação modular e tower defense desenvolvido na Godot Engine.

---

## Sobre o jogo

Um mini robô orgânico usa um teleportador quântico que o leva para um planeta desconhecido. Agora você precisa minerar, automatizar e se defender para construir um novo teleportador e voltar para casa.

---

## Características

- **Automação e Tower Defense** — Construa esteiras, britadeiras e torres automatizadas enquanto enfrenta inimigos.
- **Geração procedural** — Mapas gerados proceduralmente com FastNoiseLite, cache em PackedFloat32Array
- **Sistema de Save/Load** — Salva semente, estruturas, jogador (posição/rotação/zoom/item) com tela de loading.
- **Barra de Seleção** — Interface inferior para selecionar itens com suporte a teclas 1-4, clique, e sincronizada via signals
- **Controles** — Teclado, mouse, tela sensível ao toque (joystick virtual) e controle (analógico direito para cursor, A/B para ações)
- **Som** — Som ambiente em loop, SFX de colocar/destruir estruturas, partículas ao interagir
- **Preview de Construção** — Indicador visual com snap ao grid, rotação (R), preview semi-transparente, detecção de área ocupada

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

## Elementos do jogo

| Item | Descrição |
|---|---|
| Broca | Mina minério automaticamente |
| Esteira | Transporta itens entre estruturas |
| Canhão | Torre de defesa automática |
| Núcleo | Coleta itens e armazena |
| Bronze | Recurso minerável |

---

## Tecnologias

- **Engine:** Godot 4.7
- **Linguagem:** GDScript
- **Resolução:** 1280×720, stretch `canvas_items` + `keep`
- **Input:** `emulate_touch_from_mouse = true`

---

## Como jogar

1. Clone o repositório
2. Abra o projeto na Godot Engine 4.7+
3. Execute a cena principal (`scenes/mundo.tscn`)

---

## Estrutura do Projeto

| Diretório | Finalidade |
|---|---|
| `scripts/` | Código-fonte GDScript |
| `scenes/` | Cenas Godot (.tscn) |
| `scenes/posicionaveis/` | Estruturas construíveis |
| `scenes/itens/` | Itens/recursos |
| `scenes/particles/` | Efeitos de partícula |
| `sound/` | Áudio (ambiente, SFX) |
| `images/` | Sprites e tilesets |

---

## Licença

Distribuído sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais informações.
