## Context

Atualmente, `MapasCarrosselPage` delega a renderização de mapas interativos ao método `_defaultMapBuilder`, que instancia `MapaInterativoPage`. Embora `CarrosselItemData` e `via_functions.dart` capturem `escaladaContextNome`, esse dado é omitido no construtor de `MapaInterativoPage`, fazendo com que `_focusedItemIndex` permaneça 0 (primeira via do marcador).

Além disso, a chave `ValueKey` do `MapaInterativoPage` no carrossel é atrelada estritamente ao caminho da imagem (`${cragId}_${caminhoImagem}_${imageProviderOverride}`). Portanto, transições para outras vias na mesma imagem de fundo reutilizam o mesmo `_MapaInterativoPageState`. Para que essa reutilização ocorra de forma fluida e reativa, o ciclo de vida `didUpdateWidget` precisa gerenciar o foco da via e o zoom sem que o estado da imagem seja recriado.

## Goals / Non-Goals

**Goals:**
- Garantir que abrir o croqui a partir de qualquer escalada (1ª, 2ª, 3ª, etc.) selecione a via correta e enquadre seus pontos.
- Preservar integralmente o cache e as texturas da imagem de fundo quando o usuário navegar entre vias presentes na mesma imagem.
- Condicionar animações de zoom e translação estritamente a mudanças reais de seleção (`selectionChanged == true`), mantendo pan e zoom manuais intactos em reconstruções cosméticas.
- Alinhar a telemetria do nó ativo (`FeedbackMetadataCollector`) com a via efetivamente focada.

**Non-Goals:**
- Alterar o protocolo de comunicação protobuf ou o esquema de indexação de mapas (`CroquiMapIndex`).
- Modificar o comportamento de navegação por toque direto nos marcadores do mapa enquanto o usuário já está interagindo na tela.

## Decisions

### Decisão 1: Manter a `ValueKey` focada na Mídia e Tratar Seleção no `didUpdateWidget`
- **Abordagem Escolhida**: Manter `key: ValueKey('${widget.cragId}_${item.mapaCaminhoImagem}_${widget.imageProviderOverride.hashCode}')` no `_defaultMapBuilder` e implementar a lógica de sincronização de seleção no `didUpdateWidget` de `_MapaInterativoPageState`.
- **Alternativa Rejeitada**: Adicionar `initialSelectedId` e `escaladaContextNome` na `ValueKey`. Essa alternativa forçaria o descarte e a recriação do `State` a cada mudança de via, descarregando a imagem da GPU e causando piscamento de tela (flicker) e perda do estado do `InteractiveViewer`.
- **Justificativa**: Preserva máxima performance visual e fluidez ao navegar por vias adjacentes em um mesmo setor ou parede.

### Decisão 2: Repasse Explícito de `escaladaContextNome` no Carrossel
- **Abordagem Escolhida**: Em `MapasCarrosselPage._defaultMapBuilder`, repassar explicitamente `escaladaContextNome: item.escaladaContextNome` para `MapaInterativoPage`.
- **Justificativa**: Conecta a intenção capturada no botão da tela de via com o mecanismo de resolução de abas de rota já existente no `MapaInterativoPage`.

### Decisão 3: Condicionar Câmera Estritamente a `selectionChanged == true`
- **Abordagem Escolhida**: Comparar `widget.initialSelectedId != oldWidget.initialSelectedId || widget.escaladaContextNome != oldWidget.escaladaContextNome`. Apenas quando verdadeiro:
  1. Atualizar `_selectedId` e recalcular `_focusedItemIndex`.
  2. Resetar `_usuarioAjustouZoomManualmente = false`.
  3. Agendar via `addPostFrameCallback` a animação de câmera com `_zoomToPoints`.
- **Justificativa**: Impede que reconstruções causadas por mudanças externas (ex: live reload, rotação, eventos de áudio/conectividade) interrompam a exploração manual do usuário no mapa.

### Decisão 4: Atualização Precisa do Nó de Telemetria
- **Abordagem Escolhida**: Em `_updateFeedbackNode`, utilizar `refs[_focusedItemIndex]` (com fallback defensivo para bounds) em vez de `refs.first`.
- **Justificativa**: Assegura que diagnósticos e relatórios de feedback registrem exatamente a via que está ativa na tela.

## Risks / Trade-offs

- **[Risco: ViewportSize ou ImageSize indisponíveis no momento do didUpdateWidget]** → Mitigado utilizando `WidgetsBinding.instance.addPostFrameCallback` para garantir que o layout esteja resolvido e validando nulos antes de chamar `_zoomToPoints`.
- **[Risco: Conflito de animação de zoom em didUpdateWidget com animação anterior ativa]** → Mitigado pelo cancelamento implícito de `_animationController.forward()` em `_zoomToPoints`, que substitui a interpolação anterior sem saltos bruscos.
