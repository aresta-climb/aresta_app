## Why

Atualmente, o aplicativo espalha a lógica de abrir mapas para uma entidade (Pico, Grupo, Setor) por vários arquivos (`mapa_interativo.dart`, `via_functions.dart`, etc.). Quem chama a navegação precisa verificar manualmente se uma entidade tem 1 ou >1 mapas para decidir se chama `AppNav.toMapaInterativo` ou `AppNav.toMapasCarrossel`. Essa duplicação complica funcionalidades como o botão "Up" do mapa interativo, que não consegue navegar corretamente para o mapa da entidade pai. Ao centralizar a lógica de navegação de mapas, simplificamos as chamadas e melhoramos a arquitetura.

## What Changes

- Atualizar o `MapasCarrosselPage` para lidar de forma inteligente com um único mapa (ignorando o `PageView` e a interface do carrossel quando `mapas.length == 1`).
- Introduzir um único helper de navegação unificado `AppNav.toMapas` que recebe uma entidade/referência e abre seus mapas.
- Remover completamente a rota exposta `AppNav.toMapaInterativo` e o `MapaInterativoNode`. Toda navegação para mapas, sem exceção, passará pelo novo helper, forçando a abstração em nível de API. O `MapaInterativoPage` passa a ser um componente interno usado apenas pelo `MapasCarrosselPage`.
- Refatorar todos os locais atuais que chamam a navegação de mapas para usar o novo helper unificado.
- Atualizar o `MapHierarchyResolver` para retornar a entidade pai (Grupo ou Pico) em vez de apenas o primeiro mapa, e atualizar o botão "Up" para usar o `AppNav.toMapas`.
- **Garantia de Qualidade**: Toda a mudança será implementada via Desenvolvimento Orientado a Testes (TDD), buscando 100% de cobertura de testes unitários. Além disso, todo método novo ou modificado será totalmente documentado com docstrings em Dart.

## Capabilities

### New Capabilities
- `unify-map-navigation`: Helper central de navegação de mapas e tratador de Carrossel atualizado para mapas únicos, estritamente testado e documentado.

### Modified Capabilities
None.

## Impact

- `AppNav` (lógica de navegação, remoção do método legado)
- `MapasCarrosselPage` (modificação de UI para suportar itens únicos e atuar como container universal)
- `MapHierarchyResolver` (hierarquia de navegação)
- `navigation_tree.dart` (remoção do `MapaInterativoNode`)
- Vários arquivos de funções de view (`via_functions.dart`, `mapa_interativo.dart`, `pico.dart`, etc.)
- Suítes de testes em todos esses domínios.
