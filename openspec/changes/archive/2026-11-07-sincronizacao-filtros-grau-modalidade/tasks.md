# Tasks

## 1. Domínio de Filtragem e Isolamento por Categoria (`EstadoFiltrosUnificado`)

- [x] 1.1 Escrever testes unitários em `frontend/test/utils/filtro_grau_escalada_test.dart` validando que restringir o grau de `Via` oculta boulders quando `modalidadeEspecifica == null` (aba Setores), que restringir o grau de `Boulder` oculta vias, que definir ambos mantém ambas as categorias filtradas, e que `isModalidadeAtivaNosSetores`, `isCategoriaAtivaNosSetores`, `temFiltrosAtivosParaModalidade` e `obterContadorModalidade` isolam corretamente as abas específicas (verificando a falha inicial no ciclo Red)
- [x] 1.2 Implementar em `frontend/lib/utils/filtro_grau_escalada.dart` os métodos `categoriasComFiltroGrau`, `isModalidadeAtivaNosSetores`, `isCategoriaAtivaNosSetores` e `temFiltrosAtivosParaModalidade`, além de atualizar `filtrarEscaladas` e `obterContadorModalidade`, verificando que todos os testes de `frontend/test/utils/filtro_grau_escalada_test.dart` passam com 100% de cobertura (Green/Refactor)

## 2. Painel de Filtros e Sincronização Visual (`PainelFiltrosIndice`)

- [x] 2.1 Escrever testes de widget em `frontend/test/widgets/painel_filtros_indice_test.dart` validando que na aba "Setores" ambas as réguas (`Via` e `Boulder`) permanecem visíveis ao filtrar grau de uma categoria, que o chip da outra modalidade é desmarcado automaticamente, que a régua inativa fica esmaecida (`Modalidade inativa`) e reativa a modalidade ao ser arrastada, e que a barra externa exibe apenas o chip `[Vias: ... ✕]` limpando tudo em 1 clique (verificando a falha inicial no ciclo Red)
- [x] 2.2 Atualizar `frontend/lib/widgets/painel_filtros_indice.dart` para manter ambas as réguas renderizadas na aba "Setores", aplicar estado esmaecido (`Opacity` e badge `'Modalidade inativa'`) às categorias inativas, reativar a categoria ao interagir com sua régua, sincronizar os `FilterChip`s de modalidade com `isModalidadeAtivaNosSetores` e omitir chips externos de modalidade quando derivados do grau, verificando a aprovação integral de `frontend/test/widgets/painel_filtros_indice_test.dart` com 100% de cobertura

## 3. Páginas de Exploração (`SetoresPage`, `GrupoPage` e `SetorPage`)

- [x] 3.1 Escrever testes de widget em `frontend/test/pages/pico_subpages/setores_page_test.dart`, `frontend/test/pages/grupo_test.dart` e `frontend/test/pages/setor_test.dart` validando que filtrar grau de via oculta setores exclusivos de boulder e badges de boulder na aba "Setores", mantém o contador limpo `Boulders (total)` na aba de boulders e lista todos os boulders ao alternar para a aba "Boulders" (e vice-versa)
- [x] 3.2 Atualizar `frontend/lib/pages/setor.dart` (e ajustes necessários em `frontend/lib/pages/pico_subpages/setores_page.dart` e `frontend/lib/pages/grupo.dart`) para utilizar `temFiltrosAtivosParaModalidade` na formatação dos rótulos das abas de modalidade e garantir o isolamento de abas específicas, verificando que os testes das três páginas passam com 100% de cobertura

## 4. Verificação Integrada

- [x] 4.1 Executar `openspec validate sincronizacao-filtros-grau-modalidade --strict` e a suíte de testes das áreas impactadas via `flutter test`, garantindo zero avisos de análise estática (`flutter analyze`) e 100% de aprovação
