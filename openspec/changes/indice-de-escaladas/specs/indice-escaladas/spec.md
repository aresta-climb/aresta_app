## Purpose

Disponibiliza um índice remissivo e catálogo interativo de todas as escaladas de um pico, permitindo filtrar e ordenar por modalidade, dificuldade, setor e conquistador.

## ADDED Requirements

### Requirement: Ponto de Entrada do Índice no Hub do Pico
O aplicativo SHALL exibir um cartão de navegação dedicado ao Índice de Escaladas na tela principal do pico (`PicoDetailsPage`), posicionado em destaque ao lado do cartão de Setores em grade de 2 colunas, com título "ÍNDICE DE ESCALADAS" e subtítulo "Todas as vias e boulders filtrados por grau e tipo".

#### Scenario: Visualização dos pontos de entrada no pico
- **WHEN** o usuário abre a página principal de um pico
- **THEN** o sistema exibe dois cartões principais no topo lado a lado: "SETORES" e "ÍNDICE DE ESCALADAS"
- **AND** tocar no cartão "ÍNDICE DE ESCALADAS" navega para a tela do índice de escaladas daquele pico

### Requirement: Abas Dinâmicas por Modalidade Existente
A tela do Índice de Escaladas SHALL renderizar abas de navegação dedicadas apenas para as modalidades de escalada que possuam ao menos uma rota cadastrada no pico (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`), sem exibir uma aba genérica "Todas".

#### Scenario: Pico com esportivas e boulders
- **WHEN** o usuário abre o Índice de Escaladas de um pico que possui apenas vias esportivas e boulders
- **THEN** apenas as abas "Esportivas" e "Boulders" são renderizadas
- **AND** a primeira aba disponível fica selecionada por padrão

#### Scenario: Pico com apenas uma modalidade
- **WHEN** o usuário abre o Índice de Escaladas de um pico exclusivo de uma única modalidade (ex: apenas Boulders)
- **THEN** a lista dessa modalidade é exibida diretamente sem necessidade de alternância de abas

### Requirement: Filtro Contextual por Faixa de Grau e Dificuldade
O aplicativo SHALL disponibilizar filtragem de dificuldade compatível com o sistema de graduação da modalidade selecionada, oferecendo atalhos de faixas predefinidas e ajuste de limite inicial e final.

#### Scenario: Filtragem na aba de Esportivas ou Móveis
- **WHEN** a aba selecionada for "Esportivas" ou "Móveis"
- **THEN** as opções de filtro de grau utilizam a escala brasileira de vias (1º a 12ºc)
- **AND** a seleção de uma faixa restringe os resultados às escaladas dentro dos limites selecionados

#### Scenario: Filtragem na aba de Boulders
- **WHEN** a aba selecionada for "Boulders"
- **THEN** as opções de filtro de grau utilizam a escala V (V0 a V16)

#### Scenario: Filtragem na aba de Multienfiadas
- **WHEN** a aba selecionada for "Multienfiadas"
- **THEN** o filtro de grau baseia-se na dificuldade máxima da via
- **AND** filtros opcionais de exposição (E1 a E5) e duração (D1 a D6) são disponibilizados

### Requirement: Painel de Filtros Expansível com Persistência por Aba
O aplicativo SHALL disponibilizar um painel expansível e colapsável (*expando*) no topo da listagem, permitindo configurar filtros por setor, conquistador, dificuldade e filtro de clássicas (★), preservando o estado dos filtros de cada aba de modalidade de forma independente.

#### Scenario: Alternância entre abas preservando filtros
- **WHEN** o usuário aplica um filtro de grau na aba "Esportivas", navega para a aba "Boulders" e depois retorna para a aba "Esportivas"
- **THEN** os filtros anteriormente aplicados na aba "Esportivas" permanecem ativos e a listagem continua filtrada

#### Scenario: Expansão e colapso do painel
- **WHEN** o usuário colapsa o painel de filtros
- **THEN** o painel é recolhido e exibe apenas chips com os filtros atualmente aplicados
- **AND** a área de visualização da lista é maximizada

### Requirement: Apresentação do Card de Escalada no Índice
Cada item da listagem do Índice SHALL exibir o grau formatado em destaque visual, nome da escalada, modalidade, contagem de proteções (ou metragem/duração), indicador de clássica (se aplicável), identificação geográfica do setor/grupo de origem e ação de navegação para a tela de detalhes.

#### Scenario: Toque no card de escalada
- **WHEN** o usuário clica em um item da lista no Índice de Escaladas
- **THEN** o aplicativo navega para a página de detalhes da escalada (`ViaPage`)
- **AND** o estado da lista (filtros, busca textual e posição do scroll) é retido em memória

### Requirement: Preservação de Estado no Retorno da Detalhes da Via
O aplicativo SHALL garantir que o acionamento do botão voltar (`<-` da barra de aplicativo ou botão/gesto de retorno do sistema operacional) a partir da página de detalhes da via retorne o usuário à tela do Índice de Escaladas exatamente no mesmo estado de rolagem e filtragem anterior.

#### Scenario: Retorno ao Índice após inspecionar uma via
- **WHEN** o usuário acessou uma via através do Índice de Escaladas e aciona o botão voltar
- **THEN** o aplicativo retorna para o Índice de Escaladas
- **AND** a posição de rolagem e os filtros ativos são idênticos aos de antes do clique
