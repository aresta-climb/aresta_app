## Context

Veja `proposal.md` para a motivação e contexto do problema.
Atualmente, a apresentação de detalhes de vias em `via_functions.dart` e o cartão flutuante em `mapa_interativo.dart` sofreram divergências após o commit `5ebf65e`:
- A seção de descrição foi alocada após blocos de metadados históricos e de conquista.
- O cartão flutuante do mapa perdeu a prévia de descrição, e exibe subtítulo sem contagem de proteções.
- As proteções eram divididas em dois cartões: "Proteções" e "Paradas".
- Vias mistas (que possuem chapeletas fixas e peças móveis) não recebem rotulagem diferenciada no app.

## Goals / Non-Goals

**Goals:**
- Reordenar as seções na página de detalhes da via para priorizar a leitura imediata de segurança e beta da rocha (Descrição).
- Unificar proteções intermediárias e na parada em um único cartão de métricas no formato `X+Y` (ex: `3+2`), eliminando o cartão isolado de "Paradas".
- Exibir prévia higienizada de até 2 linhas da descrição no cartão flutuante do mapa interativo com reticências.
- Enriquecer o subtítulo do cartão do mapa com `Modalidade | Grau | Proteções` (`X+Y`).
- Detectar dinamicamente a modalidade "Mista" em `ViaMovel` (com proteções intermediárias fixas) e `ViaMultiplasEnfiadas` (com enum MISTA).

**Non-Goals:**
- Modificar o schema Protobuf (`croqui.proto`) ou os binários de dados existentes.
- Criar novos campos de banco de dados ou migrações de backend.
- Alterar o comportamento de expansão completa de Markdown na tela do mapa (o usuário toca em "Mais Info" para ver o Markdown completo).

## Decisions

### Decisão 1: Reordenação na árvore de widgets em `via_functions.dart`
A hierarquia vertical de widgets em todos os builders de via (`_buildViaEsportiva`, `_buildViaMovel`, `_buildBoulder`, `_buildMultipitch` e `_buildHighline`) seguirá rigorosamente:
1. `_buildTopBadges` e `_buildInteractiveMapButton`
2. Grid de `statCards` métricos (Dificuldade, Proteções `X+Y`, Extensão, etc.)
3. `_buildHeader('Descrição')` + `OfflineMarkdown(data: via.descricao)`
4. Informações técnicas ("Informações", "Peças Móveis", "Parada & Ancoragem")
5. Card "HISTÓRICO & CONQUISTA"
6. Botões de ação secundária ("Apoie a Manutenção" e "Assistir Vídeo Beta")

*Alternativas consideradas:*
- Colocar botões de ação logo abaixo da descrição: descartado para evitar poluição visual entre o beta e as informações técnicas; mantê-los no rodapé preserva o foco na rocha.

### Decisão 2: Formatação unificada `X+Y` para o cartão de Proteções
- Implementar helper `formatarProtecoes(int intermediarias, int parada)`:
  - Se ambas forem 0 / vazias: não renderiza o card.
  - Se intermediárias > 0 ou parada > 0: exibe `${intermediarias}+${parada}`.
- O card utiliza o título `'Proteções'` e ícone `Icons.shield_outlined`.
- Ajustar `buildOutlineStatCard` em `common_functions.dart` para suportar `maxLines: 2` no título, permitindo quebras suaves se necessário em telas muito estreitas.

*Alternativas consideradas:*
- Manter dois cartões e renomear "Paradas" para "Proteções na parada": descartado porque consome espaço vertical no grid e é menos intuitivo que a notação consagrada `X+Y`.

### Decisão 3: Prévia textual da descrição no cartão flutuante
- No método `_buildBaseCard` em `mapa_interativo.dart`, adicionar parâmetro opcional `String? description`.
- Quando presente e não vazia, sanitizar com `stripMarkdownForSubtitle(description)` e renderizar um widget `Text` com `maxLines: 2`, `overflow: TextOverflow.ellipsis`, `fontSize: 13` e cor `context.colors.ashGrey`.
- O acréscimo de altura é de ~25-30px, mantendo o cartão flutuante enxuto e o mapa desimpedido.

*Alternativas consideradas:*
- Renderizar `OfflineMarkdown` com rolagem: descartado (reintroduziria o bug de consumo excessivo de tela de antes do commit `5ebf65e`).
- Sistema de acordeão "Ver mais": descartado nesta fase em favor da simplicidade (Princípio VI: Simplicidade e Anti-Abstração), já que o botão "Mais Info" abre a tela completa.

### Decisão 4: Helper centralizado para Modalidade e Proteções
- Criar funções utilitárias em `via_functions.dart`:
  - `getModalidadeEscalada(Escalada escalada)`: retorna `'Esportiva'`, `'Mista'`, `'Móvel'`, `'Boulder'`, `'Multipitch'` ou `'Highline'`.
  - `getProtecoesString(Escalada escalada)`: retorna string `X+Y` ou vazia se não aplicável.
- Usar esse helper em `mapa_interativo.dart`, `setor_functions.dart` e `global_search.dart` para garantir consistência em 100% do app.

## Risks / Trade-offs

- **[Risco] Vias com 0 proteções intermediárias mas com parada (ex: 0+2)**
  - *Mitigação*: A notação `0+2` explicita claramente ao escalador que não há grampos na via, mas há 2 na parada de rapel.
- **[Risco] Quebra de linha no subtítulo do cartão flutuante em telas muito pequenas (<= 320px)**
  - *Mitigação*: O subtítulo usa `Text` com formatação compacta (`Esportiva | 6°sup | 3+2`). O texto ocupa ~140px, deixando ampla margem para telas de qualquer tamanho.

## Migration Plan

- Como as alterações são puramente no frontend e consomem o modelo Protobuf existente, não há necessidade de migração de banco de dados ou backend.
- O rollout é imediato na próxima compilação do app.
