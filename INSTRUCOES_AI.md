# Instruções para IA — Factolyth

Este documento define as convenções e regras que uma IA deve seguir ao modificar ou estender o código do jogo **Factolyth**. Leia com atenção antes de propor qualquer alteração.

---

## Idioma

- Todo código, comentários e commits devem estar em **Português (Brasil)**.
- Nomes de classes, métodos e variáveis seguem o padrão **snake_case** do GDScript.

---

## Estrutura do Projeto

| Diretório | Finalidade |
|---|---|
| `scripts/` | Código-fonte GDScript e shaders |
| `scenes/` | Cenas Godot (`.tscn`) |
| `scenes/posicionaveis/` | Cenas de objetos que o jogador constrói (broca, esteira) |
| `scenes/itens/` | Cenas de itens/recursos (bronze) |
| `recurso/` | Resources customizados (`ItemConstrucao.tres`) |
| `images/` | Sprites e tilesets |
| `images/itens/` | Sprites de itens/recursos |
| `tilesets/` | Tilesets do editor de tiles |

---

## Convenções de Código (GDScript)

- **extends** sempre na primeira linha.
- **const** em MAIÚSCULAS com underscore: `MAX_SPEED`.
- **@export** antes de variáveis que aparecem no Inspector.
- **@onready** para referências a nós da cena.
- Propriedades públicas em **snake_case**.
- Use **type hints** (`: int`, `: float`, `: Vector2`, etc.) em todas as variáveis.
- Funções públicas devem ter nomes descritivos em snake_case.
- Prefira `match` a cadeias longas de `if/elif`.
- Use `print()` com emojis para depuração de ações importantes.

---

## Grupos (Groups)

Usados para identificação de tipos entre scripts sem acoplamento direto:

| Grupo | Usado por | Finalidade |
|---|---|---|
| `"item"` | `bronze.gd` (`_ready`) | Identifica itens transportáveis. Esteiras e Núcleo checam este grupo. |
| `"esteira"` | `esteira.tscn` (nó raiz) | Identifica esteiras. Broca checa este grupo no Detector. |

Adicione via `add_to_group("nome")` no `_ready()` ou no editor Godot.

---

## Camadas de Colisão (Collision Layers)

| Layer | Usado por |
|---|---|
| 1 (default) | broca, esteira, núcleo (StaticBody2D), bronze (CharacterBody2D), todas as Area2D (Detector, Coletor, Area2D da esteira, AreaChecagem) |
| 2 | jogador (`collision_layer = 2`, `collision_mask = 0`) |

**Regras:**
- Jogador está na layer 2 com mask 0 → **não colide com nada** (quando houver paredes, colocá-las na layer 1 e ajustar `collision_mask` do jogador para 1)
- Todos os objetos e áreas interagem entre si na layer 1 (padrão)

---

## Mapa e Grid

- O grid é **32×32 pixels**.
- O cursor alinha ao centro do tile: `floor(pos / 32) * 32 + 16` (cursor.gd:49).
- O `mundo.tscn` carrega `tilesets.tscn` como `Mapa`, `jogador.tscn`, `nucleo.tscn` e uma broca inicial.

---

## Fluxo de Seleção de Item (Teclas 1 / 2)

```
Tecla 1 → jogador.gd:_unhandled_input()
         → marker.equipar_item(recurso_esteira)
         → cursor.gd:equipar_item()
             → item_atual = recurso_esteira
             → rotation_atual = 0
             → _atualizar_preview_visual()
                 → remove preview antigo
                 → instancia cena do recurso
                 → duplica o Sprite/AnimatedSprite2D
                 → marca com meta "is_construction_preview"
                 → alpha 0.4, aplica rotação
                 → adiciona como filho do Marker2D

Tecla 2 → mesmo fluxo com recurso_broca
```

Os recursos são atribuídos ao jogador via Inspector em `jogador.tscn` como `SubResource` inline (não arquivos `.tres` externos).

---

## Cursor (`cursor.gd`) — Detalhado

### Posicionamento no Grid (cursor.gd:36-50)
1. Obtém posição bruta do mouse
2. Calcula área visível da câmera: `tamanho_tela / camera.zoom`
3. Trava o mouse aos limites visíveis (clamp)
4. Alinha ao grid 32×32 com offset +16 (centro do tile)

### Preview Visual (cursor.gd:70-92)
1. Remove previews antigos (meta `"is_construction_preview"`)
2. Instancia a `cena_objeto` do `item_atual` com `is_preview = true`
3. Busca `AnimatedSprite2D` ou `Sprite2D` na cena instanciada
4. Duplica o sprite, define alpha 0.4, aplica rotação e adiciona como filho
5. Descarta a instância temporária

### Colocação (cursor.gd:98-109)
1. Verifica se `_area_esta_ocupada()` (has_overlapping_bodies ou has_overlapping_areas)
2. Se desocupado: instancia a cena, posiciona no grid, adiciona ao `current_scene`

### Remoção (cursor.gd:111-115)
1. Itera sobre corpos e áreas sobrepostas em `AreaChecagem`
2. Dá `queue_free()` em tudo (exceto o próprio jogador `$".."`)

### Rotação (cursor.gd:65-68)
- Tecla R: `rotation_atual += 90` (mod 360)
- Se `compensar_rotacao_90` for true, aplica offset de -90° (alinhamento visual)

---

## ItemConstrucao (`item_construcao.gd`) — Resource

Classe base para todo item posicionável. Configurada como `class_name ItemConstrucao extends Resource`.

```gdscript
@export var nome: String                    # "Broca", "Esteira"
@export var cena_objeto: PackedScene         # Cena a instanciar
@export var compensar_rotacao_90: bool       # Ajuste visual de rotação
```

Para adicionar um novo item construível:
1. Criar cena em `scenes/posicionaveis/` herdando `StaticBody2D`
2. Adicionar `var is_preview := false`
3. No `_ready()`, checar `is_preview` e desativar processamento se verdadeiro
4. Se tiver detecção, usar `await get_tree().physics_frame` antes de checar colisões
5. Criar `ItemConstrucao.tres` em `recurso/` (ou SubResource inline no jogador.tscn)
6. Atribuir o recurso ao jogador no editor Godot

---

## Broca (`broca.gd`) — Detalhado

### Estrutura da Cena (`broca.tscn`)

```
StaticBody2D (broca.gd)
├── AnimatedSprite2D (animação 2 frames, 6 fps)
├── CollisionShape2D (Rectangle 32×32)
├── Detector (Area2D, collision_layer=2)
│   └── CollisionShape2D (Circle, raio ~31.8)
└── TimerProducao (Timer, sem autostart)
```

### Funcionamento Interno

1. **`_ready()`** (broca.gd:18-34):
   - Se `is_preview`, sai imediatamente
   - Configura `timer_producao.wait_time = tempo_producao`
   - Conecta `timer_producao.timeout → _on_timer_producao_timeout`
   - Aguarda 1 physics frame (`await get_tree().physics_frame`) para Area2D atualizar
   - Chama `verificar_esteira()`

2. **`verificar_esteira()`** (broca.gd:37-47):
   - Itera sobre `detector.get_overlapping_bodies()`
   - Se encontrar corpo no grupo `"esteira"`, chama `iniciar_producao(corpo)`

3. **`iniciar_producao(esteira)`** (broca.gd:51-55):
   - Guarda referência da esteira em `esteira_atual`
   - Inicia o timer se estiver parado

4. **`_on_timer_producao_timeout()`** (broca.gd:79-91):
   - Verifica se `esteira_atual` ainda existe
   - Checa se há algum item do grupo `"item"` sobreposto no Detector (saída bloqueada)
   - Se desocupado: chama `spawnar_bronze(esteira_atual)`

5. **`spawnar_bronze(esteira)`** (broca.gd:65-74):
   - Instancia constante `BRONZE = preload("res://scenes/itens/bronze.tscn")`
   - Adiciona como filho de `get_parent()` (o mundo)
   - Posiciona na `global_position` da esteira

6. **Detecção dinâmica**: `_on_detector_body_entered` e `_on_detector_body_exited` iniciam/param produção quando esteiras entram ou saem do alcance.

---

## Esteira (`esteira.gd`) — Detalhado

### Estrutura da Cena (`esteira.tscn`)

```
StaticBody2D (grupo: "esteira")
├── AnimatedSprite2D (3 frames, 5 fps)
├── CollisionShape2D (Rectangle 22×33)
├── RayDireita (RayCast2D, target 32,0)
├── RayEsquerda (RayCast2D, target -32,0)
├── RayCima (RayCast2D, target 0,-32)
├── RayBaixo (RayCast2D, target 0,32)
└── Area2D (collision_mask=3)
    └── CollisionShape2D (Rectangle 20×32)
```

### Funcionamento Interno

- Em `_physics_process`, itera sobre corpos sobrepostos na `Area2D`
- Se o corpo está no grupo `"item"`:
  - Define `body.impulso = Vector2.UP.rotated(global_rotation) * VELOCIDADE` (100 px/s)
  - Define `body.esteira_atual_pos = global_position` (para alinhamento em curvas)
- A direção do impulso é o "para cima" da esteira rotacionada (UP = direção padrão, rotacionada conforme o ângulo da esteira)

**Raycasts** (RayDireita, RayEsquerda, RayCima, RayBaixo) estão presentes no cenário mas **não são usados no código atual**. Existem como preparação para lógica futura de conexão entre esteiras.

---

## Bronze (`bronze.gd`) — Detalhado

### Estrutura da Cena (`bronze.tscn`)

```
CharacterBody2D (collision_layer=2, collision_mask=0)
├── CollisionShape2D (Circle)
└── Sprite2D
```

### Funcionamento Interno

1. **`_ready()`**: adiciona ao grupo `"item"`

2. **`_physics_process(delta)`**:
   - **Se recebeu impulso** (está em uma esteira):
     - Reseta `no_chao` e `tempo_fora_da_esteira`
     - Aplica `velocidade = impulso`
     - **Alinhamento em curvas**: se `esteira_atual_pos` é conhecido:
       - Movimento horizontal (`abs(direcao.x) > 0.5`): centraliza Y na posição da esteira com `lerp`
       - Movimento vertical (`abs(direcao.y) > 0.5`): centraliza X na posição da esteira com `lerp`
   - **Se NÃO recebeu impulso** (caiu no chão):
     - Desacelera com `lerp(Vector2.ZERO, 0.2)`
     - Reseta `esteira_atual_pos`
     - Acumula `tempo_fora_da_esteira += delta`
     - Após 3s no chão: `queue_free()`
   - Chama `move_and_slide()`
   - Reseta `impulso = Vector2.ZERO`

---

## Núcleo (`nucleo.gd`) — Detalhado

### Estrutura da Cena (`nucleo.tscn`)

```
StaticBody2D (nucleo.gd)
├── Node2D ("Nucleo")
├── CollisionShape2D (Rectangle 17×19)
├── Sprite2D (nucleo.png, scale 2×)
└── Coletor (Area2D, collision_mask=3)
    └── CollisionShape2D (Rectangle 81×83)
```

### Funcionamento Interno

1. Em `_ready()`, conecta `coletor.body_entered → _on_coletor_body_entered`
2. Quando um corpo entra no Coletor:
   - Verifica se está no grupo `"item"`
   - Lê `body.tipo` para identificar o tipo de item (fallback: `"bronze"`)
   - Incrementa o contador em `inventario[tipo_item]`
   - Deleta o item com `body.queue_free()`

---

## Jogador (`jogador.gd`)

### Estrutura do `jogador.tscn`

```
Node2D ("Jogador")
└── CharacterBody2D ("player")  (jogador.gd)
    ├── Sprite2D (criatura.png)
    ├── CollisionShape2D (Circle)
    ├── Camera2D
    └── Marker2D (cursor.gd)
        ├── Sprite2D (target_round_b, com shader pulsante)
        └── AreaChecagem (Area2D)
            └── CollisionShape2D (Circle, raio 13)
```

### Funcionamento

- Movimento 8-directional com WASD (aceleração/atrito)
- Rotação suave da nave na direção do movimento
- Zoom com scroll do mouse (min 0.5–0.7, max 1.4–1.5)
- Teclas 1/2 chamam `marker.equipar_item(recurso)` passando os `ItemConstrucao`
- Os recursos (SubResources) são configurados inline no `jogador.tscn`, não em arquivos `.tres` externos (os arquivos em `recurso/` estão desatualizados/sem `cena_objeto`)

---

## Fluxo Completo (Exemplo: Broca → Esteira → Núcleo)

```
1. Jogador pressiona 2 → seleciona Broca
   → Cursor mostra preview da Broca
   → Clique esquerdo no grid → Broca é instanciada

2. Jogador pressiona 1 → seleciona Esteira
   → Cursor mostra preview da Esteira
   → Clique esquerdo ao lado da Broca → Esteira é instanciada

3. Broca detecta esteira via Detector.body_entered
   → iniciar_producao(esteira) → Timer começa (2s)

4. Timer dispara → _on_timer_producao_timeout()
   → Verifica saída desocupada (sem item no Detector)
   → spawnar_bronze(esteira_atual)
   → Bronze aparece na posição da esteira

5. Esteira pega o Bronze em sua Area2D
   → Bronze.impulso = direção * 100 px/s
   → Bronze.esteira_atual_pos = posição da esteira
   → Bronze se move na direção da esteira

6. Bronze chega ao Núcleo → entra no Coletor
   → _on_coletor_body_entered
   → inventario["bronze"] += 1
   → Bronze é deletado
```

---

## Shaders

- Shaders ficam em `scripts/` com extensão `.gdshader`.
- Prefira `shader_type canvas_item`.
- Use `uniform` com `hint_range` para parâmetros ajustáveis no Inspector.
- O shader atual (`cursor.gdshader`) aplica pulsação de escala e brilho no cursor.

---

## Input Map

Ações existentes (configuradas em `project.godot`):

| Ação | Tecla |
|---|---|
| `move_left` / `move_right` / `move_up` / `move_down` | WASD |
| `interact` | E |
| `instanciar_objeto` | Mouse 1 |
| `remover_objeto` | Mouse 2 |
| `selecionar_esteira` | 1 |
| `selecionar_broca` | 2 |
| `cancelar_construcao` | 0 |
| `rotacionar_objeto` | R |

Não crie novas ações de input diretamente em código; use o Input Map do editor Godot.

---

## Cena Principal

A cena principal é `res://scenes/main.tscn` (não existe ainda). Quando criada, deve instanciar `mundo.tscn` (que por sua vez instancia `jogador.tscn` e `nucleo.tscn`).

---

## Boas Práticas

- Não remova ou renomeie pastas/diretórios existentes sem consultar.
- Commits em português, no presente do indicativo, imperativo ("Adiciona sistema de minério", não "Adicionei sistema...").
- Sempre mantenha compatibilidade com Godot 4.6+.
- Prefira o sistema de Resources (`ItemConstrucao`) a hardcoded enums ou dicionários para definir novos itens.
- Ao adicionar um novo item/recursos, siga o padrão existente: grupo `"item"`, variável `tipo`, script herda `CharacterBody2D`.
- Ao adicionar um novo construível, siga: grupo específico, script herda `StaticBody2D`, variável `is_preview`, preview check no `_ready()`.
- Use `await get_tree().physics_frame` no `_ready()` antes de checar colisões de Area2D.
- Prefira `is_in_group("nome")` a `is_instance_of()` para verificar tipos entre sistemas.
