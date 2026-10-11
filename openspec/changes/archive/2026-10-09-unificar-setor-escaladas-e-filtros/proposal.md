# Proposal

## Why

Atualmente, a página de setor (`SetorPage`) opera de forma desconectada da arquitetura moderna de exploração do Aresta Climb: utiliza estado local isolado, possui uma grade de botões de ordenação legada, não oferece suporte a filtros por graduação, modalidade, conquistadores ou clássicas, e ignora as preferências definidas pelo usuário no restante do aplicativo.

Ao unificar a página de setor na mesma infraestrutura reativa de exploração já adotada nas páginas de Pico e Grupo (`GerenciadorFiltrosCroqui` e `PainelFiltrosIndice`), proporcionamos consistência visual e funcional completa de ponta a ponta. Ao mesmo tempo, preservamos as especificidades críticas para quem está na base da rocha: o número de referência do croqui/mapa no badge da escalada, a ordenação de abas de modalidades por volume decrescente de vias (sem a redundância de uma aba agregadora "Todas") e o suporte a rolagem e realce pulsante (`scrollToEscalada`).

## What Changes

- **Integração com `GerenciadorFiltrosCroqui` na `SetorPage`**: O setor passa a ouvir e aplicar os filtros e ordenações globais persistidos por `cragId`, garantindo que critérios aplicados no Pico ou Grupo permaneçam ativos ao entrar no setor.
- **Substituição da Grade de Ordenação pelo `PainelFiltrosIndice`**: Remove o enum e widget legado `buildEscaladaSortGrid`, introduzindo a barra de "Filtros e Ordenação" 100% clicável com chips roláveis e modal com sliders de régua adaptativa específica para o setor, conquistadores e clássicas.
- **Abas de Modalidade por Volume Decrescente**: Em setores com modalidades mistas (ex: esportivas e boulders), as abas são ordenadas pela quantidade de escaladas cadastradas (a modalidade com mais vias abre selecionada por padrão) e a aba agregadora "Todas" é dispensada. Se o setor possuir apenas uma única modalidade, a barra de abas é ocultada automaticamente.
- **Abertura Contextual de Aba para `scrollToEscalada`**: Quando o setor for aberto através do toque em uma via no croqui ou busca, a aba ativa é direcionada para a modalidade da referida via, permitindo rolagem automática e animação de realce suave.
- **Card de Escalada Contextual com Rótulo do Croqui**: O card de escalada no setor adota o acabamento visual moderno do ecossistema Aresta (`CardIndiceEscalada` / padrão visual consistente), mantendo no badge à esquerda o número/letra do traçado do croqui (ex: `1`, `M1 A`) e o grau com proteções no subtítulo técnico.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability introduzida. -->

### Modified Capabilities
- `exploracao-setores-escaladas`: Expande os requisitos de exploração e filtragem reativa para abranger a página de setor, definindo o comportamento de abas por volume, filtros globais herdados e exibição de rótulos de croqui nos cards.

## Impact

- **Código Afetado**:
  - `frontend/lib/pages/setor.dart`: Refatoração para adotar `GerenciadorFiltrosCroqui`, `PainelFiltrosIndice` e gerenciamento de abas.
  - `frontend/lib/view/function_library/setor_functions.dart`: Limpeza e depreciação da grade de ordenação legada (`buildEscaladaSortGrid`, `_buildEscaladaSortCard`).
  - `frontend/lib/utils/indexador_escaladas.dart`: Helper opcional `indexarEscaladasDoSetor` e integração dos rótulos de croqui.
  - `frontend/lib/widgets/card_indice_escalada.dart`: Suporte a exibição contextual de rótulos de mapa/croqui e ocultação de localização redundante.
  - `frontend/test/pages/setor_test.dart`: Atualização e ampliação substancial dos testes de widget.
- **APIs / Dependências**: Nenhuma nova dependência externa; reutiliza inteiramente a infraestrutura existente de telemetria, gerenciamento de estado e widgets.
