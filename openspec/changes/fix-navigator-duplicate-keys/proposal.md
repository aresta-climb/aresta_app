## Why

O aplicativo atualmente apresenta um crash com a mensagem `!keyReservation.contains(key)` no `Navigator` do Flutter ao abrir o mapa interativo e clicar em uma via em circunstâncias específicas. Isso acontece porque o `TreeNavigationController` empilha um novo `ViaNode` que possui um contexto diferente (ex: possui um `setorNome`) de um `ViaNode` anterior que não o possuía, mas ambos os nós geram exatamente a mesma string em seus métodos `toString()`. Como o `main.dart` utiliza `ValueKey(node.toString())` para identificar as páginas, o Flutter encontra chaves duplicadas no array de páginas e causa o crash. Resolver isso previne a quebra do aplicativo durante esses fluxos de navegação envolvendo o mapa.

## What Changes

- Modificar o `toString()` do `ViaNode` para incluir `$cragId`, `$setorNome` e `$grupoNome`.
- Modificar o `toString()` do `SetorNode` para incluir `$cragId` e `$grupoNome`.
- Modificar o `toString()` do `GrupoNode` para incluir `$cragId`.
- Modificar o `toString()` do `MapaInterativoNode` para incluir `$cragId`, `$setorContextNome` e `$grupoContextNome`.
- Garantir que todas as subclasses de `NavNode` incorporem em suas saídas de `toString()` todos os campos que são utilizados em suas respectivas verificações lógicas de igualdade no `_isSameNode()`.

## Capabilities

### New Capabilities

*(Nenhuma capacidade nova introduzida)*

### Modified Capabilities

- `navigation`: Os requisitos para a unicidade dos nós na árvore de navegação estão sendo atualizados para garantir que nós que são considerados logicamente distintos (pelo `_isSameNode`) também produzam representações em string distintas para o `Navigator` do Flutter.

## Impact

- `frontend/lib/navigation/navigation_tree.dart` (Atualizações nos métodos `toString()` das subclasses de `NavNode`)
- Geração de páginas do `Navigator` do Flutter no `main.dart` (corrigido implicitamente pela atualização das representações em string dos nós)
