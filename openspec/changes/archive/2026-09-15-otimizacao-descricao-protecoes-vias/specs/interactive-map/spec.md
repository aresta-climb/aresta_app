## ADDED Requirements

### Requirement: Prévia Textual da Descrição no Cartão Flutuante
O cartão flutuante do mapa interativo SHALL exibir uma prévia textual da descrição da via selecionada, formatada em texto simples (removendo marcações Markdown através de `stripMarkdownForSubtitle`), limitada a no máximo 2 linhas com reticências (`maxLines: 2, overflow: TextOverflow.ellipsis`), mantendo a altura compacta do cartão e preservando a visibilidade do croqui.

#### Scenario: Via selecionada no mapa com descrição cadastrada
- **WHEN** o usuário seleciona um ponto de interesse que resolve para uma via com `descricao` não vazia
- **THEN** o cartão flutuante exibe o texto da descrição limpo de marcações Markdown
- **AND** o texto é truncado com reticências após 2 linhas caso exceda o espaço
- **AND** o botão "Mais Info" continua disponível para abrir a visualização completa

#### Scenario: Via selecionada no mapa sem descrição cadastrada
- **WHEN** o usuário seleciona uma via cuja `descricao` é vazia
- **THEN** o cartão flutuante não exibe a área de texto de prévia, mantendo o espaçamento compacto original

### Requirement: Exibição de Proteções e Modalidade no Subtítulo do Cartão Flutuante
O subtítulo do cartão flutuante da via no mapa interativo SHALL incluir a quantidade de proteções na notação `<intermediárias>+<parada>` adjacente à modalidade e ao grau (ex: `Esportiva | 6°sup | 3+2` ou `Mista | 6°sup | 3+2`).

#### Scenario: Via com proteções cadastradas selecionada no mapa
- **WHEN** uma via esportiva ou móvel possui `quantidadeProtecoesIntermediarias > 0` ou `quantidadeProtecoesParada > 0`
- **THEN** o subtítulo do cartão exibe `[Modalidade] | [Grau] | <intermediárias>+<parada>`
- **AND** se a via for móvel com proteções intermediárias fixas, a modalidade exibida SHALL ser "Mista"

#### Scenario: Via sem proteções cadastradas selecionada no mapa
- **WHEN** a via selecionada não possui proteções intermediárias nem na parada (ex: boulder)
- **THEN** o subtítulo exibe apenas `[Modalidade] | [Grau]` sem o segmento de proteções
