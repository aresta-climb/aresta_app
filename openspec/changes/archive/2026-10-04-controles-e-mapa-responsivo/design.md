# Technical Design: controles-e-mapa-responsivo

## Context

Atualmente, `SetoresPage` e `GrupoPage` organizam a exploração de setores e escaladas empilhando:
1. `MapaThumbnail` (com proporção `largura / altura` livre, podendo atingir 600px+ em imagens verticais).
2. Abas de exploração (`TabBar` com Setores e Modalidades).
3. `PainelFiltrosIndice` (accordion inline que empurra todo o conteúdo ao expandir).
4. `BarraOrdenacaoExploracao` (barra fixa de botões sempre visível abaixo dos filtros).

Essa disposição fragmenta o controle visual da página e reduz drasticamente o espaço disponível para a visualização das escaladas. Veja motivação completa em `proposal.md`.

## Goals / Non-Goals

**Goals:**
- **Banner Responsivo de Mapa**: Limitar a altura do `MapaThumbnail` a no máximo `260px` via `BoxConstraints(maxHeight: 260)`, preenchendo a largura com `BoxFit.cover` e `Alignment.center`.
- **Barra de Controles Compacta em Linha Única**: Transformar a apresentação externa em um cabeçalho compacto de controles acompanhado por uma trilha horizontal de chips em `SingleChildScrollView(scrollDirection: Axis.horizontal)`, impedindo quebra de linhas.
- **Chip de Ordenação Dinâmico**: Renderizar chip de ordenação na barra externa apenas quando fora de "Padrão ▲", com botão `✕` para restauração imediata do padrão.
- **Modal Bottom Sheet de Controles**: Abrir um modal reativo contendo duas seções claras: "Ordenação" (Padrão, Grau, Alfabético e ▲/▼) e "Filtros" (Grau, Localização, Conquistadores e Clássicas).
- **Ação de Limpar Abrangente**: Botão "Limpar" no modal que zera todos os filtros e restaura a ordenação para o padrão.
- **In-App Feedback e Árvore de Navegação**: Adicionar `ControlesNode` no `TreeNavigationController` e incluir o botão de feedback na extrema direita do cabeçalho do Bottom Sheet.

**Non-Goals:**
- Não alterar a tela cheia de navegação interativa de mapas (`MapaInterativoPage`).
- Não modificar a lógica de ordenação por mediana ou pesos de graduação em `EstadoFiltrosUnificado`.

## Decisions

### 1. Limite de Altura com `BoxConstraints(maxHeight: 260)` no `MapaThumbnail`
- **Decisão**: Envolver o `AspectRatio` existente com um `ConstrainedBox(constraints: BoxConstraints(maxHeight: 260))`.
- **Por que não altura fixa de 260px?**: Mapas panorâmicos (16:9), que em telas mobile têm cerca de 210px de altura, não devem ser forçados a esticar ou exibir barras vazias. O `maxHeight` preserva mapas menores e limita apenas os verticais ou quadrados.
- **Enquadramento**: A imagem interna continua com `fit: BoxFit.cover` e `alignment: Alignment.center`, garantindo que o centro da rocha/croqui e o botão central "Abrir Mapa Interativo" fiquem em foco.

### 2. Barra de Chips em Linha Única com Rolagem Horizontal
- **Decisão**: Na barra externa da página, exibir o botão `[ ⚙ Controles ]` seguido por um `SingleChildScrollView(scrollDirection: Axis.horizontal)` contendo a lista de chips ativos.
- **Por que não `Wrap`?**: Um `Wrap` em múltiplas linhas recriaria o problema de canibalização do espaço vertical sempre que o usuário combinasse múltiplos filtros. A linha única mantém a barra em altura estável (~44px) e oferece rolagem horizontal natural.

### 3. Integração de Ordenação e Filtros no Modal Bottom Sheet
- **Decisão**: Substituir a `BarraOrdenacaoExploracao` fixa na página por uma seção "Ordenação" no topo do Bottom Sheet de Controles, mantendo os mesmos botões de tríade e alternador de direção.
- **Reatividade**: Qualquer alteração na ordenação ou filtros no Bottom Sheet atualiza o `EstadoFiltrosUnificado` imediatamente em tempo real, sem necessidade de botão "Aplicar".

### 4. Chip de Ordenação Dinâmico com Reset Rápido
- **Decisão**: 
  - Se `tipoOrdenacao == padrao && direcaoCrescente == true`: nenhum chip de ordenação é exibido.
  - Caso contrário: exibe chip correspondente (ex: `Padrão ▼`, `Grau ▲`, `Grau ▼`, `A-Z ▲`, `Z-A ▼`).
  - Ao tocar no `✕` do chip, o `EstadoFiltrosUnificado` é atualizado para `tipoOrdenacao: padrao, direcaoCrescente: true`.

### 5. Navegação e In-App Feedback com `ControlesNode`
- **Decisão**: Criar a classe `ControlesNode extends NavNode` em `nos_modais.dart`.
- **Fluxo**:
  - Ao abrir o bottom sheet: `ctrl.navigateTo(ControlesNode(parent: ctrl.currentNode))` (ou registro correspondente).
  - Ao fechar o bottom sheet (`whenComplete` / drag down): `ctrl.pop()`.
  - Cabeçalho do modal renderiza `buildFeedbackButton(context)` na extrema direita (Row com Spacer), garantindo que a captura de tela inclua o modal aberto e que os metadados de telemetria e issue registrem a rota `Pico -> Setores -> Controles`.

## Risks / Trade-offs

- **[Corte de detalhes em mapas muito verticais no thumbnail]** → Mitigação: O thumbnail é meramente um banner e ponto de entrada (`call-to-action`). Tocar nele abre instantaneamente o visualizador em tela cheia com zoom, rotação e pan.
- **[Acessibilidade de scroll no Bottom Sheet em telas compactas]** → Mitigação: O Bottom Sheet utiliza `isScrollControlled: true` com altura máxima de até 85% da tela (`DraggableScrollableSheet` ou `SingleChildScrollView` delimitado), permitindo rolar com fluidez todos os seletores e sliders.
