# Design

## Context

A arquitetura do Aresta Climb utiliza o `GerenciadorFiltrosCroqui` como singleton reativo responsável por armazenar o `EstadoFiltrosUnificado` associado ao `cragId`. Esse estado unificado controla os filtros ativos (modalidades, faixas de grau, conquistadores e clássicas) e o modo/direção de ordenação (`TipoOrdenacaoExploracao`).

Enquanto as páginas de Pico (`SetoresPage`) e Grupo (`GrupoPage`) já utilizam essa infraestrutura através do componente `PainelFiltrosIndice`, a página de setor (`SetorPage`) permaneceu com uma implementação isolada baseada em um enum local `EscaladaSortMode` e numa grade de três botões (`buildEscaladaSortGrid`).

Veja mais detalhes sobre a motivação em `proposal.md` e os requisitos em `specs/exploracao-setores-escaladas/spec.md`.

## Goals / Non-Goals

**Goals:**
- Conectar `SetorPage` ao `GerenciadorFiltrosCroqui`, garantindo herança e sincronização contínua de filtros e ordenação entre Pico, Grupo e Setor.
- Substituir a grade estática de ordenação pelo `PainelFiltrosIndice` completo, com barra 100% clicável, chips de filtros ativos e modal com sliders de régua adaptativa.
- Organizar as abas de modalidade por volume decrescente de escaladas cadastradas no setor, omitindo a barra de abas quando o setor possuir modalidade única e dispensando a aba agregadora "Todas".
- Preservar o badge de referência do croqui/mapa (ex: `1`, `M1 A`) à esquerda no card de escalada, exibindo o grau e proteções no subtítulo técnico.
- Assegurar a continuidade do fluxo de navegação direta (`scrollToEscalada`), garantindo que a aba correspondente à via seja pré-selecionada e o realce suave pulsante continue funcionando.
- Remover o código legado de ordenação em `setor_functions.dart`.

**Non-Goals:**
- Não alterar a exibição de cabeçalho (`SliverAppBar` com imagem de capa em parallax ou título colapsável), nem os widgets de descrição em Markdown e mapa thumbnail.
- Não introduzir novos nós na árvore de navegação; os nós existentes `SetorNode` e `ViaNode` continuam inalterados.
- Não unificar os cards de escalada do setor com os de pico/grupo no formato idêntico de grau no badge, conforme decisão explícita do usuário de priorizar o rótulo do croqui no setor.

## Decisions

### 1. Estado Unificado via `GerenciadorFiltrosCroqui`
- **Decisão:** A `SetorPage` passará a obter o estado de filtros via `GerenciadorFiltrosCroqui.instance.obterFiltros(widget.cragId)` e registrar um listener em `initState`, removendo-o no `dispose`.
- **Alternativas consideradas:**
  - *Manter filtros isolados específicos para o setor:* Rejeitado, pois criava uma experiência fragmentada onde o usuário precisava refazer seus filtros a cada setor acessado.
  - *Passar filtros via parâmetro do construtor:* Rejeitado, pois inviabilizaria a reatividade global e complicaria o roteador da árvore de navegação.

### 2. Ordenação das Abas por Volume Decrescente
- **Decisão:** As escaladas do setor são agrupadas por modalidade e ordenadas por contagem decrescente: `_modalidadesDisponiveis.sort((a, b) => contagem[b]!.compareTo(contagem[a]!))`.
  - Se `_modalidadesDisponiveis.length > 1`: exibe o `TabBar` no container de cabeçalho.
  - Se `_modalidadesDisponiveis.length <= 1`: não renderiza o `TabBar`.
  - A aba inicial selecionada (`initialIndex`) será:
    - Se `scrollToEscalada != null`: a modalidade da escalada alvo.
    - Caso contrário: a modalidade com maior volume (índice 0).
- **Alternativas consideradas:**
  - *Manter aba agregadora "Todas":* Rejeitado após deliberação de produto, pois setores são escopos menores e o usuário prefere focar na modalidade predominante sem redundâncias.

### 3. Integração do `PainelFiltrosIndice` no Setor
- **Decisão:** O `PainelFiltrosIndice` será instanciado na `SetorPage` fornecendo:
  - `setoresDisponiveis`: `[widget.setor.nome]` (restringindo o filtro de setores ao setor corrente).
  - `faixasGrauDisponiveis`: calculado via `calcularFaixasGrauDisponiveis` para as vias da aba ativa (ou de todo o setor).
  - `conquistadoresDisponiveis` e `temClassicasDisponiveis`: extraídos das vias do setor.
- **Alternativas consideradas:**
  - *Criar um componente novo de filtros simplificado:* Rejeitado, pois feriria os princípios de simplicidade e reuso do `AGENTS.md`. O `PainelFiltrosIndice` já lida com projeção contextual nativamente.

### 4. Card de Escalada no Setor (`CardSetorEscalada` ou `CardIndiceEscalada` adaptado)
- **Decisão:** Renderizar as escaladas com card moderno baseado na identidade visual do aplicativo (`colors.caveShadow`, bordas `colors.graniteEdge`, cantos 14px), contendo:
  - Badge à esquerda com o indicador e rótulo do mapa (`rotulos.mapIndicator` e `rotulos.resolvedLabel`).
  - Título com nome da via e estrela âmbar (`Icons.star`) para clássicas.
  - Subtítulo com `Modalidade | Grau • Proteções`.
  - Encapsulamento com `_buildEfeitoRealceAlvo` quando `isTarget` for verdadeiro (`scrollToEscalada == escalada`).
- **Alternativas consideradas:**
  - *Usar `CardIndiceEscalada` forçando o grau no badge:* Rejeitado, pois na base da parede o número do traçado no croqui é o elemento mais crítico de identificação visual.

### 5. Eliminação de Código Morto
- **Decisão:** Deprecar e remover `EscaladaSortMode`, `buildEscaladaSortGrid` e `_buildEscaladaSortCard` de `setor_functions.dart`, eliminando código redundante e simplificando os arquivos de visão.

## Risks / Trade-offs

- **[Risco] Escalada alvo (`scrollToEscalada`) não visível se filtros ativos a ocultarem**:
  - *Mitigação:* Se o usuário veio via busca ou QR code para uma via específica que não atende aos filtros atuais do croqui (ex: faixa de grau restrita), o sistema pode temporariamente exibir uma mensagem informativa ou garantir que a via seja apresentada com destaque para não quebrar a expectativa de navegação.
- **[Risco] RangeSlider com grau único em setores homogêneos**:
  - *Mitigação:* A infraestrutura de `calcularFaixasGrauDisponiveis` e régua adaptativa já possui salvaguarda que expande automaticamente em $\pm 1$ grau quando `minValor == maxValor`.
