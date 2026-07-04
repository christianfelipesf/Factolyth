# AGENTS.md — Factolyth

## Comandos essenciais

- **Abrir no Godot**: Editor Godot 4.7+, importar `project.godot`
- **Exportar HTML5**: Preset "Web" em `export_presets.cfg` — testar local com `$ godot --headless --export-release Web`
- **Único autoload**: `SaveManager` em `res://scripts/save_manager.gd` — F5 salva, F9 carrega, F12 deleta saves
- **Validar compilação (após editar scripts)**: `& "C:\Users\Christian Felipe\Desktop\Godot_v4.7-stable_win64.exe" --headless --path . --import --quit --verbose 2>&1`
  - Ou no terminal `/godot-check` se estiver usando opencode TUI

## Arquitetura

- **Entrypoint real**: `scenes/mundo.tscn` (instancia `jogador.tscn` + `tilesets.tscn` + estruturas iniciais)
- **project.godot** refere `main.tscn` que **não existe** — criar só quando necessário
- **Jogador**: `CharacterBody2D` raiz de `jogador.tscn` (sem wrapper Node2D) → `player/` com `Camera2D` + `Marker2D` (cursor)
- **Caminho save**: `SaveManager` busca jogador como `"Jogador"` (string literal) no grupo `"jogador"`
- **Preview**: `cursor.gd` duplica sprite da cena (não instancia o objeto completo)

## Convenções (violações causam erros)

- **Português (Brasil)**: código, comentários, commits
- **`event.accept()` não existe em Godot 4** — usar `get_viewport().set_input_as_handled()`
- **`abs(float)`** causa type inference error — usar `absf()`
- **Input actions** devem ser criadas no Input Map do editor, nunca em código com `InputMap.add_action()`
- **HTML5**: `DirAccess.open("res://")` trava — usar `preload()` individuais

## Camadas de colisão

| Layer | Quem |
|---|---|
| 1 | construções (StaticBody2D), items (CharacterBody2D), todas Area2D |
| 2 | jogador |
| 3 | paredes (TileMapLayer `parede`, `collision_mask` do jogador inclui layer 3) |

## Grid

- Tile 32×32, centro: `floor(pos / 32) * 32 + 16`
- Multi-tile: `ItemConstrucao.tamanho_grid: Vector2i`, offset = `(tamanho - 1) * 16`
- `cursor.gd` limpa previews via meta `"is_construction_preview"` (não por tipo)

## Input (ações do editor)

| Ação | Tecla |
|---|---|
| `interact` | E (cicla itens) |
| `cancelar_construcao` | 0 |
| `rotacionar_objeto` | R |
| `instanciar_objeto` / `remover_objeto` | Mouse 1 / 2 |
| `salvar_jogo` / `carregar_jogo` / `deletar_saves` | F5 / F9 / F12 |

Teclas 1-4 e controle (A/B, analógico direito) são tratados em código (`jogador.gd._unhandled_input`, `cursor.gd`).

## Agents disponíveis

`.opencode/agents/`:
- `factolyth-dev.md` — desenvolvimento geral (Godot 4.6 legado)
- `factolyth-godot47.md` — modernização 4.7 + priorizar engine sobre script
- `godot-review.md` — revisão de código (read-only)

## Referências

- `INSTRUCOES_AI.md` — documentação detalhada de convenções e fluxos
