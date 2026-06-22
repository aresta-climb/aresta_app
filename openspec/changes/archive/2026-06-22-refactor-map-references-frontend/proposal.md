## Why

A atualização do banco de dados (`aresta_db`) introduziu uma breaking change na forma como Pontos de Interesse (POIs) são representados nos croquis: as entidades não possuem mais `id_no_mapa`. Em vez disso, os mapas declaram explicitamente `referencias` com suporte a cross-linking (Grupo, Setor, Escalada) e ajustes finos de câmera. Além disso, as escaladas, setores e grupos receberão um novo campo `indice_mapa_padrao`. O frontend precisa ser totalmente refatorado para suportar essas novidades, delegando a busca dessas referências para o sistema de navegação em árvore já existente e alterando o comportamento da UI para reagir a referências explícitas.

## What Changes

- **Extração da lógica de resolução**: O código que mapeia nomes de grupos, setores e escaladas para objetos Protobuf será extraído do `PageListenableBuilder` para um utilitário genérico (`DatasetResolver`).
- **Resolução de Escopo Implícito**: As referências omitidas (ex: sem `setor` explicitado) farão o merge do contexto atual no frontend antes de serem resolvidas.
- **Indexação Antecipada no Mapa**: O mapa interativo passará a resolver suas referências em seu carregamento, armazenando dicionários rápidos de `ID -> Referências` e `Referência -> Objeto Resolvido` na memória.
- **Card Dinâmico**: Ao tocar em um POI, a interface apresentará um card contextual (Escalada, Setor ou Grupo) que se integra fluidamente à classe estática `AppNav`.
- **Mudança na ação "Ver no Mapa"**: Telas de detalhamento deixarão de usar ID e passarão a navegar por `TargetContext` explícito.
- **Adição do `indice_mapa_padrao`**: O backend receberá a adição desse campo (em grupos, setores e escaladas) e uma task para linter testar os usos será anotada em `../aresta_db/TODO.md`.
- **Qualidade de Código**: Todo o novo código inserido seguirá a prática de Test-Driven Development (TDD) com o objetivo de alcançar 100% de cobertura de testes unitários.

## Capabilities

### New Capabilities
- `map-context-resolution`: Nova capacidade arquitetural de usar a árvore de dados/nav para transformar as referências textuais do mapa em ponteiros de memória em tempo real.

### Modified Capabilities
- `interactive-map`: A interação do mapa suportará exibição de entidades além de escaladas (Setores, Grupos) e navegação cross-linking.
- `view-on-map`: A capacidade de centralizar o mapa em uma entidade a partir de outras páginas será alterada para buscar referências ativas e respeitar o `mapa_padrao`.

## Impact

- **Navegação (Tree Navigation)**: Leve adaptação no `MapaInterativoNode` e reuso da árvore.
- **Componente do Mapa**: A engine do mapa será profundamente afetada para buscar e classificar referências.
- **UI**: Novos cartões de navegação no bottom do mapa.
- **Protobuf / Backend**: Edição em `croqui.proto` para adicionar o `indice_mapa_padrao`.
