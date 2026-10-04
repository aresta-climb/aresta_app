# exploracao-setores-escaladas Specification

## Purpose

Unifica o acesso e a filtragem de setores e escaladas de um pico em uma experiência coesa com abas integradas, filtros globais reativos e ordenação bidirecional por dificuldade e mediana.

## Requirements

### Requirement: Ponto de Entrada Unificado no Hub do Pico
O sistema DEVE (MUST) exibir um card unificado de destaque na página principal do pico (`PicoDetailsPage`) denominado "Setores & Escaladas", substituindo os cards separados de "Setores" e "Índice de Escaladas".

#### Scenario: Visualização do card unificado no Hub
- **WHEN** o usuário acessa a página de detalhes de um pico
- **THEN** o sistema exibe um único card principal para navegação de escaladas
- **AND** tocar nesse card transiciona o usuário para a página de exploração unificada.

### Requirement: Abas Dinâmicas de Exploração com Contadores
A página de exploração DEVE (MUST) renderizar uma barra de abas onde a primeira aba é "Setores" e as abas subsequentes representam cada modalidade de escalada existente no pico (ex: "Esportivas", "Boulders", "Móveis"). Cada aba DEVE exibir contadores dinâmicos no formato `(total)` quando não houver filtros ativos, ou `(filtradas/total)` quando houver filtros aplicados.

#### Scenario: Pico com múltiplas modalidades sem filtros
- **WHEN** o usuário abre a exploração de um pico com 13 setores, 95 vias esportivas e 40 boulders sem filtros
- **THEN** as abas exibem exatamente "Setores (13)", "Esportivas (95)" e "Boulders (40)".

#### Scenario: Contadores atualizados dinamicamente após filtragem
- **WHEN** o usuário define um filtro de grau que restringe o resultado para 4 setores e 12 vias esportivas
- **THEN** as abas passam a exibir imediatamente "Setores (4/13)" e "Esportivas (12/95)".

### Requirement: Painel de Filtros Reativo e Superset
O sistema DEVE (MUST) disponibilizar um painel expansível de filtros com estado global compartilhado. Na aba "Setores", o painel DEVE exibir o superset com filtros de modalidades ativas, sliders de grau específicos para cada modalidade, grupos, conquistadores e vias clássicas. Nas abas de modalidade, o painel DEVE exibir a projeção contextual com slider de grau daquela modalidade, setores, grupos, conquistadores e clássicas.

#### Scenario: Compartilhamento de critérios comuns entre abas
- **WHEN** o usuário seleciona um conquistador específico na aba "Setores"
- **AND** alterna para a aba "Esportivas"
- **THEN** o filtro de conquistador permanece ativo com o mesmo valor selecionado
- **AND** a lista de vias exibe apenas as vias esportivas daquele conquistador.

#### Scenario: Desativação de modalidade na aba Setores
- **WHEN** o usuário desmarca uma modalidade (ex: "Boulder") no painel da aba "Setores"
- **THEN** os setores que possuem exclusivamente aquela modalidade são omitidos da lista de setores.

### Requirement: Ocultação e Enriquecimento de Setores Filtrados
Na aba "Setores", o sistema DEVE (MUST) ocultar setores que não contenham nenhuma escalada correspondente aos filtros ativos e DEVE enriquecer o cartão de cada setor exibindo a faixa de graduação das vias e a quantidade de vias que atendem ao filtro em relação ao total.

#### Scenario: Setor sem vias correspondentes ao filtro
- **WHEN** o usuário filtra por um grau elevado inexistente em determinado setor
- **THEN** esse setor não é exibido na lista de setores.

#### Scenario: Exibição de faixa e contagem no cartão do setor
- **WHEN** o setor possui vias que atendem aos filtros aplicados
- **THEN** o cartão do setor exibe a faixa de graus (ex: "5º a 8a") e o contador de vias correspondentes (ex: "3 vias no filtro (de 10)").

### Requirement: Tríade Padronizada de Ordenação e Direção
A página DEVE (MUST) apresentar uma barra de ordenação consistente com três modos: "PADRÃO", "GRAU" e "ALFABÉTICO", acompanhada de um botão para alternar a direção da ordenação (crescente ou decrescente).

#### Scenario: Alternância de direção da ordenação
- **WHEN** o usuário toca no botão de alternância de direção de ordenação
- **THEN** o ícone do botão muda (entre seta para cima e seta para baixo)
- **AND** a ordem dos itens exibidos é imediatamente invertida.

### Requirement: Ordenação por Grau com Mediana em Setores
Ao selecionar o modo "GRAU", o sistema DEVE (MUST) ordenar a lista de escaladas pela dificuldade individual da via e a lista de setores pela mediana normalizada dos graus das vias pertencentes a cada setor, utilizando uma escala de peso unificada para equalizar modalidades distintas.

#### Scenario: Ordenação de setores por mediana de grau crescente
- **WHEN** o usuário seleciona a ordenação por "GRAU" com direção crescente na aba "Setores"
- **THEN** os setores cuja mediana das graduações é mais branda aparecem no topo da listagem.

#### Scenario: Ordenação de vias por grau
- **WHEN** o usuário seleciona a ordenação por "GRAU" na aba de uma modalidade
- **THEN** as vias são ordenadas por seu grau de dificuldade conforme a direção selecionada.
