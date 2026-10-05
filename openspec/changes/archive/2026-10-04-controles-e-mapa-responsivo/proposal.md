# Proposal: controles-e-mapa-responsivo

## Why

Atualmente, na página de exploração de setores e escaladas (`SetoresPage` e `GrupoPage`), mapas verticais ou quadrados ocupam até 600px de altura no topo da tela, empurrando o conteúdo principal (abas e setores) para fora do campo visual do usuário. Além disso, os controles de exploração estão fragmentados entre um expansor inline de filtros (que causa saltos de layout na lista) e uma barra separada de ordenação fixa, consumindo espaço vertical precioso e gerando sobreposição cognitiva.

Modernizar essa experiência através de um limite de altura responsivo no banner do mapa (`maxHeight: 260px`) e da unificação de ordenação e filtros em um modal Bottom Sheet de **"Controles"** reativo, acompanhado de uma barra de chips roláveis em linha única na página e botão de in-app feedback integrado, torna a exploração de setores rápida, ergonômica e limpa.

## What Changes

- **Limite de Altura Máxima no Mapa (`MapaThumbnail`)**: Impõe teto de altura de `260px` (`maxHeight: 260px`) mantendo preenchimento horizontal completo, recorte centralizado (`BoxFit.cover` e `Alignment.center`) e preservação da proporção original caso a imagem tenha altura inferior.
- **Unificação de Ordenação e Filtros em "Controles"**: Remove a barra isolada `BarraOrdenacaoExploracao` da página e integra as opções de ordenação (Padrão, Grau, Alfabético e direção ▲/▼) dentro do modal de Controles junto com os filtros de grau, localização, conquistadores e clássicas.
- **Modal Bottom Sheet Reativo de Controles**: Transforma o antigo expansor inline em um Bottom Sheet modal, com atualização de estado em tempo real, botão "Limpar" abrangente (que zera filtros e restaura a ordenação padrão) e botão de in-app feedback na extrema direita do cabeçalho.
- **Barra de Chips Compacta com Scroll Horizontal**: Na página de exploração, a barra de controles passa a exibir o botão "Controles" com ícone de ajustes e uma trilha horizontal de chips em linha única (scroll horizontal), evitando quebras de linha verticais.
- **Chip de Ordenação Dinâmico**: Exibe um chip com a ordenação ativa quando estiver diferente do padrão (`Padrão ▲`). Tocar no `✕` do chip restaura imediatamente a ordenação para o padrão.
- **Rastreabilidade na Árvore de Navegação**: Adiciona o nó `ControlesNode` na arquitetura de `TreeNavigationController`, garantindo que o acionamento do feedback in-app capture com precisão a rota `Pico -> Setores -> Controles`.

## Capabilities

### Modified Capabilities
- `exploracao-setores-escaladas`: Atualiza os requisitos de apresentação de filtros e ordenação, unificando-os sob o componente e modal de "Controles" com chips horizontais, chip de ordenação dinâmico e Bottom Sheet reativo com botão de feedback.
- `interactive-map`: Atualiza a especificação de renderização da miniatura do mapa (`MapaThumbnail`) para conter a altura máxima em 260px com enquadramento centralizado, garantindo que a visualização de setores permaneça acima da dobra.

## Impact

- **Código Afetado**:
  - `frontend/lib/widgets/mapa_thumbnail.dart`: Restrição de altura máxima e enquadramento.
  - `frontend/lib/widgets/painel_filtros_indice.dart`: Evolução do componente para acionar Bottom Sheet de Controles e renderizar barra de chips horizontal.
  - `frontend/lib/widgets/barra_ordenacao_exploracao.dart`: Integração ao Bottom Sheet de Controles e remoção da barra fixa solta.
  - `frontend/lib/navigation/arvore/nos_modais.dart` e `funcoes_navegacao.dart`: Inclusão do `ControlesNode` na árvore de navegação.
  - `frontend/lib/pages/pico_subpages/setores_page.dart` e `frontend/lib/pages/grupo.dart`: Atualização da composição de slivers.
- **Testes**:
  - `test/widgets/mapa_thumbnail_test.dart`
  - `test/widgets/painel_filtros_indice_test.dart`
  - `test/pages/pico_subpages/setores_page_test.dart`
  - `test/pages/grupo_test.dart`
