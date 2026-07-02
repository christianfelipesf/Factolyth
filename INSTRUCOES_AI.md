# Instruções para IA — Factolyth

Este documento define as convenções e regras que uma IA deve seguir ao modificar ou estender o código do jogo **Factolyth**.

## Idioma

- Todo código, comentários e commits devem estar em **Português (Brasil)**.
- Nomes de classes, métodos e variáveis seguem o padrão **snake_case** do GDScript.

## Estrutura do Projeto

| Diretório | Finalidade |
|---|---|
| `scripts/` | Código-fonte GDScript e shaders |
| `scenes/` | Cenas Godot (`.tscn`) |
| `scenes/posicionaveis/` | Cenas de objetos que o jogador constrói (broca, esteira) |
| `recurso/` | Resources customizados (`ItemConstrucao.tres`) |
| `images/` | Sprites e tilesets |
| `tilesets/` | Tilesets do editor de tiles |

## Convenções de Código

### GDScript

- **extends** sempre na primeira linha.
- **const** em MAIÚSCULAS com underscore: `MAX_SPEED`.
- **@export** antes de variáveis que aparecem no Inspector.
- **@onready** para referências a nós da cena.
- Propriedades públicas em **snake_case**.
- Use **type hints** (`: int`, `: float`, `: Vector2`, etc.) em todas as variáveis.
- Funções públicas devem ter nomes descritivos em snake_case.
- Prefira `match` a cadeias longas de `if/elif`.

### Sistema de Construção (Padrão Arquitetural)

- **ItemConstrucao** (`item_construcao.gd`): Classe `Resource` base para todo item posicionável. Contém `nome`, `cena_objeto` (PackedScene) e `compensar_rotacao_90` (bool).
- **Cursor** (`cursor.gd`): Marker2D que gerencia preview, grid snapping (32×32), colisão e instanciação. Usa `equipar_item()` para receber um `ItemConstrucao`.
- **Objetos posicionáveis** (broca, esteira): `StaticBody2D` com variável `is_preview`. No modo preview, desativam `_process` e física.

Para adicionar um novo item construível:
1. Criar cena em `scenes/posicionaveis/` herdando `StaticBody2D`
2. Adicionar variável `var is_preview := false`
3. No `_ready()`, checar `is_preview` e desativar processamento se verdadeiro
4. Criar `ItemConstrucao.tres` em `recurso/` apontando para a nova cena
5. Atribuir o recurso ao jogador no editor Godot

### Shaders

- Shaders ficam em `scripts/` com extensão `.gdshader`.
- Prefira `shader_type canvas_item`.
- Use `uniform` com `hint_range` para parâmetros ajustáveis no Inspector.

### Input Map

As ações de entrada estão definidas em `project.godot`. Não crie novas ações de input diretamente em código; use o Input Map do Godot.

Ações existentes:
- `move_left`, `move_right`, `move_up`, `move_down` (WASD)
- `interact` (E)
- `instanciar_objeto` (Mouse 1)
- `remover_objeto` (Mouse 2)
- `selecionar_esteira` (1), `selecionar_broca` (2)
- `cancelar_construcao` (0)
- `rotacionar_objeto` (R)

### Cena Principal

A cena principal é `res://scenes/main.tscn`. Se for criada, deve instanciar `mundo.tscn` e `jogador.tscn` como filhos.

## Boas Práticas

- Não remova ou renomeie pastas/direto/rios existentes sem consultar.
- Commits em português, no presente do indicativo, imperativo ("Adiciona sistema de minério", não "Adicionei sistema...").
- Sempre mantenha compatibilidade com Godot 4.6+.
- Prefira o sistema de Resources (`ItemConstrucao`) a hardcoded enums ou dicionários para definir novos itens.
