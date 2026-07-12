## 1. Configuração e Preparação para Testes (TDD)

- [x] 1.1 Criar ou atualizar os arquivos de teste unitário para `MapHierarchyResolver` (`map_hierarchy_resolver_test.dart`) e `AppNav` (`navigation_functions_test.dart`) para preparar para o novo comportamento de roteamento restrito a `toMapas`.
- [x] 1.2 Escrever testes unitários que devem falhar (failing tests) para o `MapHierarchyResolver` garantindo que o `MapDestination` retorne corretamente uma lista de mapas/entidades, assegurando 100% de cobertura de testes para este módulo.
- [x] 1.3 Escrever testes de widget (failing tests) para o `MapasCarrosselPage` garantindo que passar um único mapa renderize a tela sem um `PageView` e sem as setas ou paginação do carrossel.
- [x] 1.4 Garantir que todos os arquivos de teste tenham o scaffolding básico e docstrings.

## 2. Implementação Core (Fazendo os testes passarem)

- [ ] 2.1 Atualizar `MapHierarchyResolver`: Modificar o `MapDestination` para guardar uma lista de mapas (`List<CarrosselItemData> mapasData`). Adicionar docstrings detalhadas. Garantir que os testes unitários passem.
- [ ] 2.2 Atualizar `MapasCarrosselPage`: Modificar o método `_MapasCarrosselPageState.build` com um retorno antecipado para renderizar apenas o mapa único se `widget.mapas.length == 1`. Adicionar docstrings. Garantir que os testes de widget passem.
- [ ] 2.3 Atualizar `AppNav` e `navigation_tree.dart`: Remover completamente o `MapaInterativoNode` e o `AppNav.toMapaInterativo`. Renomear `AppNav.toMapasCarrossel` para `AppNav.toMapas`. Adicionar docstrings detalhadas explicando a abstração restrita. Garantir que testes unitários relacionados passem.

## 3. Refatoração dos Locais de Chamada

- [ ] 3.1 Atualizar chamadores remanescentes do `toMapaInterativo`: No `pico.dart` e demais locais que chamavam a rota legada, altere para chamar `AppNav.toMapas`.
- [ ] 3.2 Atualizar `mapa_interativo.dart` (botão "Up"): Alterar a lógica do `onPressed` para usar `AppNav.toMapas` com a lista de mapas do `upDest`. Garantir presença de docstrings adequadas.
- [ ] 3.3 Atualizar `mapa_interativo.dart` (lógica "Ver mapas"): Substituir as verificações inline `if (mapas.length > 1)` nas bottom sheets de Grupo e Setor (linhas ~650-730) pelo `AppNav.toMapas`.
- [ ] 3.4 Atualizar `via_functions.dart` ("Ver nos mapas"): Substituir as verificações inline pelo `AppNav.toMapas`. Adicionar/atualizar docstrings.

## 4. Verificação Final e Checagem de Cobertura

- [ ] 4.1 Rodar a suíte completa de testes (`flutter test`) e verificar se há 100% de cobertura de testes unitários para os módulos modificados utilizando ferramentas de coverage.
- [ ] 4.2 Rodar o aplicativo e navegar manualmente até um Setor com um único mapa. Verificar se o mapa interativo carrega corretamente sem controles de carrossel.
- [ ] 4.3 Navegar manualmente até um Grupo com múltiplos mapas. Verificar se o carrossel carrega com funcionalidade de swipe e indicadores de página.
- [ ] 4.4 Dentro do mapa interativo de um Setor, clicar no botão "Up" para navegar até os mapas do Grupo pai. Verificar o comportamento correto em casos de mapa único versus mapas múltiplos.
- [ ] 4.5 Verificar se todos os métodos, classes e propriedades novos e modificados possuem docstrings claras e descritivas.
