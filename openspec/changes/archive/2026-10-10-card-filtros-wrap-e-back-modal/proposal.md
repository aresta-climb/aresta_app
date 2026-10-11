# Proposal

## Why

Atualmente, na barra de filtros e ordenação (`PainelFiltrosIndice`), quando há filtros ou ordenação ativos, os chips são confinados em um scroll lateral na mesma linha que o botão principal, esmagando os elementos, cortando o texto dos chips pela metade na borda da tela e prejudicando a ergonomia do usuário. Além disso, ao abrir o modal bottom sheet de filtros e ordenação, o botão voltar (back do SO/Android) exige dois toques para fechar o modal e acaba fechando indevidamente a página de exploração por baixo (efeito cascata), devido ao modal ser aberto no Navigator interno com interceptores manuais conflitantes em vez de usar o rootNavigator do aplicativo.

Reestruturar o painel de filtros em um card unificado coeso com quebra de linha fluida (`Wrap`) e delegar o fechamento do modal ao `rootNavigator` restaura a estética, a legibilidade imediata dos filtros e a estabilidade da navegação do app.

## What Changes

- **Card Unificado Coeso**: Transforma a barra externa do `PainelFiltrosIndice` em um card integrado elegante com fundo escuro (`caveShadow`), borda com cantos arredondados e duas seções bem definidas:
  - **Linha Superior**: Botão "Filtros e Ordenação" 100% clicável ocupando toda a largura, com ícone de controles (`tune`), texto, badge de contagem de filtros ativos e chevron indicador (`▾`) à direita.
  - **Linha Inferior (quando houver filtros/ordenação ativos)**: Área interna do card com os chips ativos distribuídos confortavelmente via `Wrap(spacing: 8, runSpacing: 8)` em largura total, eliminando o scroll horizontal confinado e qualquer corte de texto.
- **Correção da Navegação e Botão Back do Modal**:
  - Abertura do modal bottom sheet com `useRootNavigator: true`, garantindo que o modal seja empilhado diretamente na raiz do aplicativo.
  - Remoção de interceptores manuais frágeis (`onBackInterceptor`) e flags assíncronas de fechamento que competiam com o ciclo de vida do Flutter.
  - Fechamento confiável do modal no primeiro toque do botão/gesto voltar do sistema operacional sem afetar a página pai subjacente (`SetorPage`, `PicoPage` ou `GrupoPage`), preservando a limpeza automática do nó `ControlesNode` na árvore de navegação.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability introduzida. -->

### Modified Capabilities
- `exploracao-setores-escaladas`: Atualiza a especificação da barra externa do painel de filtros para card unificado com chips em `Wrap` vertical na linha inferior e estipula o fechamento seguro e imediato do modal com o botão voltar do sistema sem fechar a página subjacente.

## Impact

- `frontend/lib/widgets/painel_filtros_indice.dart`: Atualização do layout da barra externa para card vertical coeso com `Wrap` de chips e alteração do `showModalBottomSheet` para `useRootNavigator: true`.
- `frontend/test/widgets/painel_filtros_indice_test.dart`: Testes de widget atualizados para validar o layout com `Wrap` na linha inferior e a resposta correta de pop único do SO preservando a página por baixo.
- `frontend/test/pages/setor_test.dart`, `frontend/test/pages/grupo_test.dart`, `frontend/test/pages/pico_subpages/setores_page_test.dart`: Validação de regressão nos pontos de uso do painel.
