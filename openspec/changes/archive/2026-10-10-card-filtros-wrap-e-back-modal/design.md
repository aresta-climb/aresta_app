# Design

## Context

Na arquitetura de UI do Aresta Climb, a navegação entre telas é gerida de forma declarativa pelo `TreeNavigationWrapper`, que encapsula um `Navigator` interno com `PopScope(canPop: false)` para interceptar o botão voltar e sincronizar o estado da árvore de navegação (`NavegadorArvore`). O `PainelFiltrosIndice` renderiza controles de filtro e ordenação através de um Modal Bottom Sheet e exibe um sumário externo na página. Atualmente, a barra externa usa uma `Row` com scroll horizontal que comprime os chips ao lado do botão, e o modal abre no `Navigator` interno sem `useRootNavigator`, gerando conflito de pop com o `PopScope` raiz.

Ver motivação detalhada em `proposal.md` e requisitos em `specs/exploracao-setores-escaladas/spec.md`.

## Goals / Non-Goals

**Goals:**
- Prover um card externo unificado e elegante (`caveShadow`), onde a barra superior de acionamento é 100% clicável de ponta a ponta e os chips ativos fluem naturalmente na parte inferior em `Wrap(spacing: 8, runSpacing: 8)`.
- Garantir que o botão voltar nativo do sistema operacional (Android Back) feche o modal bottom sheet de forma imediata e limpa no primeiro toque.
- Preservar a página de exploração subjacente intacta após fechar o modal.
- Manter o registro temporário de `ControlesNode` na árvore de navegação para contextualização de telemetria e envio de feedback in-app.

**Non-Goals:**
- Alterar as regras de filtragem de graus, modalidades, conquistadores ou clássicas.
- Alterar a lógica do `RangeSlider` adaptativo ou a ordenação por mediana.

## Decisions

### 1. Card Unificado com Estrutura Vertical (Coluna Integrada)
- **Decisão**: O `PainelFiltrosIndice` renderizará um único container arredondado (`BorderRadius.circular(16)`) com fundo `caveShadow` e borda `graniteEdge` (ou destacada em `rustIron` se houver filtros ativos). Dentro dele, uma `Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch)` conterá:
  1. `InkWell` no topo com 100% de largura horizontal: ícone `tune`, texto "Filtros e Ordenação", badge de contagem de filtros e seta `▾` na extrema direita.
  2. Se houver chips ativos: um espaçamento vertical e um `Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8))` contendo `Wrap(spacing: 8, runSpacing: 8, children: chips)`.
- **Alternativa Rejeitada**: Manter scroll horizontal com botão encolhido. O scroll horizontal em largura estreita corta os chips pela metade e é ergonomicamente instável.

### 2. Abertura do Bottom Sheet com `useRootNavigator: true`
- **Decisão**: Configurar `showModalBottomSheet(context: context, useRootNavigator: true, ...)`. Ao empilhar o modal na raiz do aplicativo (`MaterialApp.navigatorKey`), o `NavigatorState` raiz é quem recebe diretamente o `didPopRoute` do sistema operacional.
- **Rationale**: Como o modal está na rota superior do `rootNavigator`, o Android fecha o modal no primeiro toque de forma nativa e síncrona, sem passar pelo `PopScope(canPop: false)` do `TreeNavigationWrapper`.
- **Alternativa Rejeitada**: Tentar resolver o conflito com interceptores manuais adicionais (`onBackInterceptor`). Interceptores manuais em navigators aninhados competem com o ciclo de vida do Flutter e causam o efeito cascata de 2 toques.

### 3. Simplificação do Ciclo de Vida do `ControlesNode`
- **Decisão**: Remover a atribuição manual de `ctrl.onBackInterceptor` e flags de estado em `_abrirModalControles`. O fluxo passa a ser estritamente:
  ```dart
  ctrl?.navigateTo(ControlesNode(cragId: widget.cragId, parent: ctrl.currentNode));
  try {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      ...
    );
  } finally {
    _modalAberto = false;
    if (ctrl != null && ctrl.currentNode is ControlesNode) {
      ctrl.goBack();
    }
    _logTelemetria('colapsar_filtros');
  }
  ```
- **Rationale**: O bloco `finally` executa de maneira confiável tanto quando o usuário fecha o modal tocando fora (barreira) quanto quando toca no botão voltar do SO ou no botão fechar. O `ctrl.goBack()` restaura o nó anterior de forma atômica.

## Risks / Trade-offs

- **[Risco] Compatibilidade de testes de widget existentes**:
  - *Mitigação*: Os testes unitários e de widget que simulam o modal já utilizam `MaterialApp` como raiz. Adicionar cenários com `handlePopRoute` validando tanto o fechamento no 1º pop quanto a permanência da tela pai.
- **[Risco] Altura vertical do card quando houver muitos chips**:
  - *Mitigação*: O `Wrap` quebra linhas conforme a necessidade, empurrando a lista de vias para baixo sem sobreposição. Como os filtros ativos raramente excedem 3-5 chips, a altura ocupada permanece proporcional e legível.
