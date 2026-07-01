## Why

A navegação a partir do mapa interativo e a descoberta de mapas a partir de uma via estão incompletas e propensas a falhas (ex: botão "Mais Info" piscando sem ação quando acionado do mapa geral, e a página da via cega a mapas de grupo ou globais). Essa mudança resolve esses problemas arquiteturalmente, garantindo consistência na resolução de dependências de navegação e otimizando a performance com indexação O(1). Toda a implementação será rigorosamente baseada em TDD (Test-Driven Development) buscando 100% de cobertura de código (unit test coverage) nas regras modificadas.

## What Changes

- Modifica a assinatura de `AppNav.toVia` e de `ViaNode` para aceitar também o contexto do `grupo` além do `setor`.
- Refatora o comportamento do clique em rotas no mapa interativo para repassar à navegação o `setor` e `grupo` já resolvidos (`resolved.setor` e `resolved.grupo`).
- Adiciona a classe de domínio `ReferenceKey` para servir como Value Object de identificação unívoca de escaladas.
- Adiciona o sistema `CroquiMapIndex` que escaneia a árvore do `Pico` na inicialização e constrói um dicionário O(1) resolvendo todas as referências para os seus mapas correspondentes.
- Atualiza a UI da `ViaPage` para consumir o `CroquiMapIndex` (em vez de iterar limitadamente sobre `setor?.mapas`), permitindo visualizar a badge "Ver no mapa" independentemente de o mapa ser do setor, grupo ou global.

## Capabilities

### New Capabilities
- `croqui-map-indexing`: Indexação global e instantânea de mapas do croqui utilizando um índice invertido.

### Modified Capabilities
- `map-navigation`: Atualização dos requisitos de contexto (passando Grupo e Setor resolvidos) para assegurar transições de mapa robustas.

## Impact

- **Código Afetado**: `AppNav` (`navigation_functions.dart`), `ViaNode` (`navigation_tree.dart`), lógica de badges (`via_functions.dart`) e clique de POI (`mapa_interativo.dart`).
- **Performance**: Reduz tempo de busca da badge de mapa em tempo de renderização para O(1).
- **Qualidade e Estabilidade**: Adição de suítes de testes unitários abrangentes cobrindo 100% da nova arquitetura e das mudanças na UI, desenhadas via TDD antes da escrita de cada componente.
