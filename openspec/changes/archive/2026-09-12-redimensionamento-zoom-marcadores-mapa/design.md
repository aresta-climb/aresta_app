## Context

Ver `proposal.md` para motivação e histórico do problema.

Atualmente, o Mapa Global renderiza todos os marcadores com tamanho fixo de 120px e balões de texto com até 800px de largura e fonte grande logo acima do pino. A condição de exibição no código (`currentZoom >= 4.0`) faz com que o texto seja exibido praticamente o tempo todo. Em zooms regionais e estaduais (ex: zoom 7-8 em Minas Gerais), marcadores vizinhos colidem e criam um bloco de texto escuro e ilegível.

## Goals / Non-Goals

**Goals:**
- Implementar 3 faixas discretas de zoom no Mapa Global:
  - Macro (zoom < 7.0): Pinos pequenos (40px) sem texto.
  - Regional (7.0 <= zoom < 11.0): Pinos médios (65px) sem texto.
  - Local (zoom >= 11.0): Pinos completos (85px) com balão de texto compacto.
- Tornar o balão de texto compacto, limitando a largura máxima (`maxWidth: 220`) e aplicando truncamento com reticências (`...`) para nomes extensos.
- Garantir desempenho impecável de 60fps na navegação e gestos de pinça, disparando rebuilds apenas quando cruzar as faixas de zoom.
- Garantir 100% de cobertura de testes com TDD (testes de widget e de funções puras de renderização).

**Non-Goals:**
- Agrupamento em bolha com contadores numéricos (clusterização complexa de nós), mantendo a arquitetura simples e sem dependências pesadas externas.
- Alterações na tela de `mapa_interativo.dart` (o foco é estritamente o Mapa Global de picos).

## Decisions

### 1. Enum de Faixa de Zoom (`FaixaZoomMapa`)
- **Decisão**: Criar um enum tipado ou helper funcional para representar as faixas:
  - `macro`: zoom < 7.0
  - `regional`: 7.0 <= zoom < 11.0
  - `local`: zoom >= 11.0
- **Rationale**: Permite que o listener `onCameraMove` calcule `obterFaixaZoom(position.zoom)` e somente acione `setState` se a faixa calculada for diferente da faixa atual, evitando rebuilds redundantes e desperdício de frames.
- **Alternativas consideradas**:
  - Interpolação contínua de escala: Inviável com Google Maps Flutter porque cada alteração de tamanho exige rasterizar um novo `BitmapDescriptor`.

### 2. Compartilhamento de Ícones Genéricos nas Faixas Macro e Regional
- **Decisão**: Nas faixas `macro` e `regional`, como não há exibição de nome textual, todos os picos compartilham a mesma instância de `BitmapDescriptor` (um para 40px e outro para 65px).
- **Rationale**: Reduz drasticamente o consumo de memória e o tempo de carregamento da tela: em vez de criar dezenas de bitmaps repetidos, criamos apenas 2 ícones genéricos para essas faixas e ícones com texto sob demanda para a faixa local.
- **Alternativas consideradas**:
  - Gerar bitmaps individuais para todos os picos em todos os 3 tamanhos: Desperdiçaria memória e tempo de inicialização na GPU.

### 3. Truncamento e Redução Tipográfica do Balão
- **Decisão**: Reduzir a fonte no `createCustomMarkerBitmapWithText` para um tamanho harmônico com o pino de 85px, limitando a largura máxima para 220px com `maxLines: 1` e `ellipsis: '...'`.
- **Rationale**: Elimina o problema visível no screenshot, onde nomes como "Parque Natural Municipal das Andorinhas" ocupam quase a largura inteira da tela e encobrem múltiplos picos.

## Risks / Trade-offs

- **[Risco] Sobrecarga de memória ao inicializar muitos ícones textuais na faixa local**
  → *Mitigação*: Os ícones textuais são gerados apenas para os picos existentes na visualização e mantidos em cache indexado por ID (`Map<String, BitmapDescriptor>`).
- **[Risco] Inconsistência de resolução em telas de altíssima densidade (pixel ratio)**
  → *Mitigação*: Utilizar tamanhos proporcionais e conversão segura para bitmaps com as rotinas já testadas de `mapa_marker.dart`.
