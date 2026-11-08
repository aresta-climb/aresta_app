# Proposal

## Why

Atualmente, quando o escalador restringe a faixa de grau de uma categoria (por exemplo, filtrando graus de vias entre `7a` e `8a`), o sistema deixa passar integralmente as escaladas da outra categoria (como todos os boulders do croqui), fazendo com que setores exclusivos de boulder e badges de boulders continuem aparecendo na aba "Setores", além de exibir contadores enganosos ou bloquear abas específicas de modalidade. Sincronizar os chips de modalidade com as réguas de grau na visão agregada ("Setores") e isolar os filtros de grau/modalidade nas abas específicas de cada modalidade torna a filtragem intuitiva, previsível e livre de ruído visual.

## What Changes

- **Sincronização Reativa entre Réguas de Grau e Modalidades (Aba "Setores")**:
  - Restringir a faixa de grau de uma categoria (`Via` ou `Boulder`) quando a outra categoria não possui restrição de grau desmarca automaticamente as modalidades da outra categoria nos chips de `Modalidades`.
  - No modal da aba "Setores", as réguas de grau das categorias existentes no local (`Via` e `Boulder`) permanecem sempre visíveis (evitando saltos de layout durante o arraste), mas a régua cuja categoria estiver com todas as modalidades desmarcadas é exibida em estado visual esmaecido (`Modalidade inativa`).
  - Interagir com uma régua de grau esmaecida (ou remarcar o chip da modalidade) reativa imediatamente as modalidades daquela categoria.
  - Restaurar a régua de grau de volta para "Todos os graus" (ou remover seu chip externo) restaura automaticamente todas as modalidades quando a restrição de modalidade tiver sido derivada do filtro de grau.
- **Limpeza em 1 Clique na Barra Externa de Chips**:
  - Quando a desmarcação de uma modalidade decorre automaticamente da aplicação de um filtro de grau (ex: `Vias: 7a a 8a`), a barra externa do `PainelFiltrosIndice` exibe apenas o chip da faixa de grau (`[Vias: 7a a 8a ✕]`) e contabiliza apenas 1 filtro ativo, sem poluir a barra com chips redundantes de modalidades.
  - Chips externos de modalidade continuam sendo exibidos quando o usuário restringe modalidades manualmente.
- **Isolamento de Filtros por Modalidade nas Abas Específicas (`Esportivas`, `Boulders`, `Móveis`, etc.)**:
  - As abas dedicadas a uma modalidade específica (em `SetoresPage`, `GrupoPage` e `SetorPage`) passam a ignorar o filtro de `modalidadesAtivas` da aba "Setores" e ignorar filtros de faixa de grau de outras categorias (`Via` vs `Boulder`), aplicando apenas a faixa de grau da própria categoria e os filtros transversais compartilhados (localização, conquistador, clássicas, busca textual e ordenação).
  - Os contadores das abas de modalidade exibem `(filtradas/total)` apenas quando houver ao menos um filtro ativo aplicável àquela modalidade específica; caso contrário, exibem `(total)` limpo.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; evolução direta da exploração unificada -->

### Modified Capabilities
- `exploracao-setores-escaladas`: Atualização dos requisitos de filtragem por categoria de grau, sincronização automática com chips de modalidade, esmaecimento visual de réguas inativas sem salto de layout, supressão de chips redundantes na barra externa e isolamento de filtros e contadores nas abas específicas de modalidade.

## Impact

- **Lógica e Estado de Filtros (`frontend/lib/utils/filtro_grau_escalada.dart`)**: Evolução de `EstadoFiltrosUnificado` para distinguir restrições de modalidade manuais vs automáticas (derivadas do filtro de grau), filtrar categorias sem restrição quando outra categoria possui grau restrito na visão de setores, e isolar a avaliação de `filtrarEscaladas`, `temFiltrosAtivosParaModalidade` e `obterContadorModalidade` por modalidade específica.
- **Componente de Interface (`frontend/lib/widgets/painel_filtros_indice.dart`)**: Manutenção das réguas de ambas as categorias visíveis na aba "Setores" com estado esmaecido quando inativas, reativação ao arrastar régua inativa, sincronização automática de modalidades ao ajustar/limpar grau e omissão de chips externos de modalidade quando derivados do grau.
- **Páginas de Exploração (`frontend/lib/pages/pico_subpages/setores_page.dart`, `frontend/lib/pages/grupo.dart`, `frontend/lib/pages/setor.dart`)**: Atualização da formatação de contadores de abas e passagem de estado para respeitar o isolamento por modalidade nas abas específicas e o filtro combinado na aba "Setores".
- **Testes (`frontend/test/`)**: Testes unitários e de widget 1:1 cobrindo 100% dos novos fluxos de sincronização, esmaecimento visual, limpeza em 1 clique e isolamento entre abas.
