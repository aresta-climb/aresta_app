## Context

Atualmente, o aplicativo possui lógica espalhada em vários arquivos para verificar se uma entidade (Grupo, Setor) tem 1 ou >1 mapas. Se houver mais de 1 mapa, ele navega para `MapasCarrosselPage`; caso contrário, navega diretamente para `MapaInterativoPage`. Isso dificulta a manutenção e gera bugs, como o botão "Up" do mapa, que exibe apenas o primeiro mapa da entidade pai e perde totalmente o contexto de carrossel.

## Goals / Non-Goals

**Goals:**
- Centralizar a lógica que escolhe entre um mapa único e um carrossel de mapas dentro do `AppNav.toMapas`.
- Garantir que `MapasCarrosselPage` consiga lidar perfeitamente com a exibição de um mapa único sem a interface de carrossel quando `mapas.length == 1`.
- Simplificar o `MapHierarchyResolver` para que a navegação "Up" mantenha o acesso a todos os mapas da entidade pai.
- Aplicar princípios de Desenvolvimento Orientado a Testes (TDD) em todas as mudanças.
- Garantir 100% de cobertura de testes unitários para as novas abstrações e refatorações.
- Assegurar que docstrings completas e precisas sejam fornecidas para todos os módulos/funções novos e modificados.

**Non-Goals:**
- Remover completamente o uso do `MapaInterativoPage` fora do `MapasCarrosselPage`. (Acessos diretos muito específicos ainda podem precisar dele, embora `AppNav.toMapas` se torne o método padrão).
- Alterar como os mapas são buscados ou carregados no backend/storage.

## Decisions

1. **Desenvolvimento Orientado a Testes (TDD)**:
   - Antes de implementar as mudanças no `MapasCarrosselPage`, escreveremos testes de widget (widget tests) que passam um único mapa e validam que o `PageView` e a UI de paginação *não* estão presentes.
   - Antes de refatorar o `MapHierarchyResolver`, escreveremos testes unitários validando que o `MapDestination` completo guarda corretamente os múltiplos mapas/entidades.
2. **Atualização do MapasCarrosselPage**: Modificaremos o método `build` de `_MapasCarrosselPageState` para adicionar um retorno antecipado: `if (widget.mapas.length == 1) return _defaultMapBuilder(...)`.
3. **Abstração de AppNav.toMapas**: Usaremos `AppNav.toMapasCarrossel` (renomeando para `AppNav.toMapas`) como o helper universal. Sua docstring detalhará claramente como ele delega a renderização com base no tamanho da lista de mapas.
4. **Refatoração das Chamadas**: Substituiremos as verificações `if (mapas.length > 1)` espalhadas por `mapa_interativo.dart` e `via_functions.dart` por chamadas diretas ao `AppNav.toMapas`.
5. **Atualização do MapHierarchyResolver**: Modificaremos o `MapDestination` para guardar `List<CarrosselItemData> mapasData`. O botão "Up" será testado via testes de widget garantindo que os parâmetros corretos sejam passados.

## Risks / Trade-offs

- **Risco**: O retorno antecipado no `MapasCarrosselPage` pode interferir na inicialização padrão do contexto ou no estado da app bar.
- **Mitigação**: Garantiremos que retornar o `_defaultMapBuilder` forneça a mesma estrutura de `Scaffold` ou árvore de widgets exigida pelo `MapaInterativoPage`. Isso será amplamente verificado pela suíte de testes de widget (TDD).
