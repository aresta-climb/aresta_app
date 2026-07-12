## Context

Atualmente, o aplicativo possui lógica espalhada em vários arquivos para verificar se uma entidade (Grupo, Setor) tem 1 ou >1 mapas. Se houver mais de 1 mapa, ele navega para `MapasCarrosselPage`; caso contrário, navega diretamente para `MapaInterativoPage`. Isso dificulta a manutenção e gera bugs, como o botão "Up" do mapa, que exibe apenas o primeiro mapa da entidade pai e perde totalmente o contexto de carrossel.

## Goals / Non-Goals

**Goals:**
- Centralizar a lógica que escolhe entre um mapa único e um carrossel de mapas dentro de `AppNav.toMapas`.
- Garantir que `MapasCarrosselPage` consiga lidar perfeitamente com a exibição de um mapa único sem a interface de carrossel quando `mapas.length == 1`.
- Eliminar completamente a rota de navegação externa para `MapaInterativoPage`, forçando todos os acessos a mapas a passarem pelo `MapasCarrosselPage`. Isso garante que a abstração nunca seja "burlada" por desenvolvedores no futuro.
- Simplificar o `MapHierarchyResolver` para que a navegação "Up" mantenha o acesso a todos os mapas da entidade pai.
- Aplicar princípios de Desenvolvimento Orientado a Testes (TDD) em todas as mudanças, com 100% de cobertura de testes unitários.
- Assegurar que docstrings completas e precisas sejam fornecidas para todos os módulos/funções novos e modificados.

**Non-Goals:**
- Alterar como os mapas são buscados ou carregados no backend/storage.

## Decisions

1. **Abstração Restrita de Navegação**: Removeremos completamente o `AppNav.toMapaInterativo` e o `MapaInterativoNode` da árvore de navegação (`main.dart`, `navigation_tree.dart`). Todo acesso externo será feito por `AppNav.toMapas`, garantindo uma API única para visualização de mapas.
2. **Desenvolvimento Orientado a Testes (TDD)**:
   - Antes de implementar as mudanças, escreveremos testes de widget (widget tests) que passam um único mapa para `MapasCarrosselPage` e validam que o `PageView` e a UI de paginação *não* estão presentes.
3. **Atualização do MapasCarrosselPage**: Modificaremos o método `build` de `_MapasCarrosselPageState` para adicionar um retorno antecipado: `if (widget.mapas.length == 1) return _defaultMapBuilder(...)`.
4. **Refatoração das Chamadas**: Substituiremos as verificações `if (mapas.length > 1)` e chamadas a `toMapaInterativo` espalhadas por `mapa_interativo.dart`, `via_functions.dart` e `pico.dart` por chamadas diretas ao `AppNav.toMapas`.
5. **Atualização do MapHierarchyResolver**: Modificaremos o `MapDestination` para guardar `List<CarrosselItemData> mapasData`. O botão "Up" será testado via testes de widget garantindo que os parâmetros corretos sejam passados.

## Risks / Trade-offs

- **Risco**: O retorno antecipado no `MapasCarrosselPage` pode interferir na inicialização padrão do contexto ou no estado da app bar caso a árvore não esteja idêntica à chamada direta antiga.
- **Mitigação**: Garantiremos que retornar o `_defaultMapBuilder` forneça a mesma estrutura de `Scaffold` exigida pelo `MapaInterativoPage`. Isso será amplamente verificado pela suíte de testes de widget (TDD).
