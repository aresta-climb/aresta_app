## Purpose

Apresentação estruturada e ergonômica dos detalhes da via de escalada, incluindo ordenação prioritária de betas de segurança (Descrição), cartão unificado de proteções na notação convencional X+Y, e suporte à modalidade Mista.

## ADDED Requirements

### Requirement: Exibição Prioritária da Descrição da Via
O aplicativo SHALL exibir a seção de Descrição (contendo betas de segurança, movimentação e equipamentos recomendados) no topo do corpo da página, imediatamente após os cartões de métricas (stat cards) e antes das seções técnicas ("Informações", "Peças Móveis", "Parada & Ancoragem") e da seção "Histórico & Conquista".

#### Scenario: Visualização de via com descrição
- **WHEN** o usuário abre a página de detalhes de uma via (esportiva, móvel, boulder, multipitch ou highline) que possui descrição cadastrada
- **THEN** a seção "Descrição" é renderizada logo abaixo dos cartões de métricas (Dificuldade, Proteções, Extensão, etc.)
- **AND** precede a seção de "Informações" e o cartão de "Histórico & Conquista"

### Requirement: Cartão Unificado de Proteções na Notação Convencional
O aplicativo SHALL unificar a contagem de proteções intermediárias e proteções na parada em um único cartão de métrica intitulado "Proteções", formatado como `<intermediárias>+<parada>` (ex: `3+2`, `9+0`, `12+2`), omitindo qualquer cartão separado com rótulo isolado "Paradas".

#### Scenario: Via com proteções intermediárias e na parada
- **WHEN** uma via possui `quantidadeProtecoesIntermediarias > 0` e `quantidadeProtecoesParada > 0`
- **THEN** o sistema renderiza um único cartão com título "Proteções" e valor `<intermediárias>+<parada>` (ex: `3+2`)
- **AND** nenhum cartão com título "Paradas" é exibido

#### Scenario: Via com proteções na parada mas sem intermediárias
- **WHEN** uma via possui `quantidadeProtecoesIntermediarias == 0` (ou não preenchida) e `quantidadeProtecoesParada > 0`
- **THEN** o sistema renderiza o cartão "Proteções" exibindo `0+<parada>`

#### Scenario: Via sem nenhuma proteção informada
- **WHEN** uma via não possui proteções intermediárias nem proteções na parada cadastradas
- **THEN** o cartão "Proteções" não é renderizado no grid de métricas

### Requirement: Identificação Dinâmica da Modalidade Mista
O sistema SHALL classificar e exibir a modalidade de escalada como "Mista" quando uma via de uma enfiada do tipo `ViaMovel` possuir proteções intermediárias fixas cadastradas (`quantidadeProtecoesIntermediarias > 0`), ou quando uma via de múltiplas enfiadas possuir `tipoViaMultiplasEnfiadas == MISTA`.

#### Scenario: Via móvel com proteções intermediárias fixas
- **WHEN** a escalada for do tipo `ViaMovel` e tiver `quantidadeProtecoesIntermediarias > 0`
- **THEN** a modalidade exibida na listagem do setor e no cartão do mapa SHALL ser "Mista"

#### Scenario: Via móvel pura sem proteções intermediárias fixas
- **WHEN** a escalada for do tipo `ViaMovel` e tiver `quantidadeProtecoesIntermediarias == 0` (ou não definida)
- **THEN** a modalidade exibida na listagem do setor e no cartão do mapa SHALL ser "Móvel"

#### Scenario: Multipitch configurado como misto
- **WHEN** a escalada for do tipo `ViaMultiplasEnfiadas` com `tipoViaMultiplasEnfiadas == MISTA`
- **THEN** a modalidade exibida no cartão do mapa e na listagem do setor SHALL ser "Mista"

### Requirement: Posicionamento de Ações Secundárias no Rodapé
O aplicativo SHALL renderizar os botões de ações secundárias ("Assistir Vídeo Beta" e "Apoie a Manutenção") ao final da página de detalhes da via, posicionados após a seção de "Histórico & Conquista".

#### Scenario: Visualização de via com ações secundárias cadastradas
- **WHEN** a via possui chave Pix de manutenção ou URL de vídeo beta cadastrados
- **THEN** os respectivos botões de ação são posicionados após a seção "Histórico & Conquista", mantendo a área superior desobstruída para a leitura do beta
