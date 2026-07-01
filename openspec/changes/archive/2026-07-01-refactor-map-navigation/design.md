## Context

A navegação interativa de mapas atualmente apresenta falhas quando o mapa não está associado a um setor específico, ou quando a via tenta descobrir referências em mapas fora de seu setor de origem. O fluxo atual força o repasse do `setor` ignorando o `grupo` (o que gera exceções silenciosas de "Escalada not found") e causa bugs de navegação (como a tela piscar). Além disso, a `ViaPage` itera os mapas em tempo de renderização limitando-se apenas a `setor?.mapas`, ignorando completamente os mapas globais e de grupo.

## Goals / Non-Goals

**Goals:**
- Passar o contexto de navegação com sucesso do mapa geral ou de grupo para qualquer via, evitando exceções no `DatasetResolver`.
- Centralizar a busca por mapas numa estrutura de índice global `CroquiMapIndex`.
- Evitar confusões de duplicidade de nomes de vias usando uma chave primária sintética `ReferenceKey(grupoNome, setorNome, escaladaNome)`.
- Fornecer acesso aos mapas referentes a uma via em tempo de busca `O(1)` em todas as páginas da árvore (Via, Setor, Grupo).

**Non-Goals:**
- Não reescreveremos o sistema de renderização visual do croqui ou a engine de plotagem de SVG/pontos.
- Não alteraremos o schema do Protobuf. Apenas construiremos a lógica de frontend ao redor dos dados atuais.

## Decisions

1. **Adição de Grupo na Navegação:**
   - Adicionar `grupo` à assinatura de `AppNav.toVia` e à classe `ViaNode`. Isso garante que a resolução em `PageListenableBuilder` tenha todas as variáveis necessárias para encontrar univocamente a Via via `DatasetResolver`.

2. **Criação do Value Object `ReferenceKey`:**
   - Para termos um índice confiável, criaremos `ReferenceKey` que embala os três nomes de contexto e implementa `operator ==` e `hashCode` nativos. Ele terá um factory constructor recebendo `ResolvedDataset`.

3. **Criação de `CroquiMapIndex`:**
   - A indexação será feita por uma nova classe que receberá a árvore de `Pico` e fará um parse top-down em `pico.mapas`, `grupo.mapas` e `setor.mapas`.
   - As referências originais serão passadas pelo `DatasetResolver` na inicialização para mapear exatamente a `ReferenceKey` correta.
   - O objeto `IndexedMap` armazenado no index conterá a instância do mapa, `setorContext`, `grupoContext` e `referencedId`, preenchendo todos os requisitos que o `AppNav.toMapaInterativo` precisa no futuro.

## Risks / Trade-offs

- **Memory Overhead:** Manter o dicionário `CroquiMapIndex` na memória. *Mitigação*: Armazena apenas ponteiros (referências rasas) para os objetos já persistidos do Protobuf. O custo de memória é irrisório.
- **Injeção de Dependência:** Decidir exatamente onde injetar. *Mitigação*: Pode ser construído e cacheado em uma variável privada estática do `MapHelper` ou injetado preguiçosamente (lazily) no estado principal enquanto o `Pico` for o ativo.
