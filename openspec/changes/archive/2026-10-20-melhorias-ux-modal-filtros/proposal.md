# Proposal

## Why

Usuários relataram dois problemas de usabilidade no Modal Bottom Sheet de "Filtros e Ordenação" (issues `aresta_db#65` e `aresta_db#66`):
1. Ao tocar no seletor de conquistadores (ou localização) em picos com muitos itens cadastrados (como a Pedra Grande de Igarapé), o menu suspenso (`DropdownButton`) se expande por 100% da altura da tela. No iOS (onde não há botão de voltar nativo no rodapé), o usuário fica sem área visível para tocar fora e cancelar a abertura do menu, sendo forçado a selecionar um item indesejado para conseguir fechar o seletor.
2. Como o modal cobre a lista de resultados subjacente e só possui um ícone `✕` no cabeçalho para fechar, o usuário sente falta de um botão explícito de confirmação (`Aplicar`) ao terminar de configurar os filtros, gerando dúvida sobre se fechar pelo `✕` aplicará ou descartará as escolhas feitas.

## What Changes

- Limitar a altura máxima do menu suspenso (`menuMaxHeight: 280`) nos componentes `DropdownButton` de seleção de **Conquistadores** e de **Localização (Setores e Grupos)** dentro do `PainelFiltrosIndice`, garantindo que sempre haja ampla área livre na tela para tocar fora e dispensar o menu sem selecionar nenhum item.
- Adicionar um rodapé fixo no Modal Bottom Sheet de `PainelFiltrosIndice` contendo um botão primário de confirmação de largura total com rótulo dinâmico `Aplicar (X resultados)` (ou `Aplicar (1 resultado)` no singular / `Aplicar` quando o contador não for informado), mantendo o comportamento 100% auto-aplicado e reativo em tempo real (de modo que fechar pelo botão `Aplicar`, pelo `✕`, tocando fora ou pelo gesto/botão de voltar preserve todos os filtros aplicados).
- Passar o total de resultados filtrados da aba ativa (`totalResultados`) para o `PainelFiltrosIndice` a partir de `SetoresPage`, `GrupoPage` e `SetorPage`.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability necessária; trata-se da evolução de exploracao-setores-escaladas -->

### Modified Capabilities
- `exploracao-setores-escaladas`: Atualizar o requisito `Painel de Filtros Reativo e Superset` para exigir altura máxima controlada nos menus suspensos de localização e conquistadores (`menuMaxHeight`) e a presença do botão de ação primária no rodapé do modal com contagem dinâmica de resultados (`Aplicar (X resultados)`), preservando a aplicação reativa imediata em qualquer forma de fechamento.

## Impact

- `frontend/lib/widgets/painel_filtros_indice.dart`: Adição de `menuMaxHeight` nos `DropdownButton`s de localização e conquistadores, nova propriedade opcional `totalResultados` e rodapé fixo com botão `Aplicar (X resultados)` no modal.
- `frontend/lib/pages/pico_subpages/setores_page.dart`, `frontend/lib/pages/grupo.dart` e `frontend/lib/pages/setor.dart`: Cálculo e repasse de `totalResultados` correspondente à aba ativa para o `PainelFiltrosIndice`.
- `frontend/test/widgets/painel_filtros_indice_test.dart`, `frontend/test/pages/pico_subpages/setores_page_test.dart`, `frontend/test/pages/grupo_test.dart` e `frontend/test/pages/setor_test.dart`: Testes comportamentais validando o limite de altura dos menus suspensos e o botão `Aplicar (X resultados)` reativo no modal.
