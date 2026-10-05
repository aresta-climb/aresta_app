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
O sistema DEVE (MUST) disponibilizar uma barra de "Controles" na página de exploração que aciona um Modal Bottom Sheet reativo com estado global compartilhado. Na página principal, a barra DEVE exibir uma trilha de chips em linha única com rolagem horizontal (scroll horizontal), contendo chips com remoção rápida (`✕`) para filtros ativos e para ordenação não-padrão. O Modal Bottom Sheet DEVE conter duas seções distintas: "Ordenação" e "Filtros". Na aba "Setores", a seção de filtros DEVE exibir o superset com modalidades ativas, sliders de grau específicos para cada modalidade, grupos, conquistadores e vias clássicas. Nas abas de modalidade, a seção de filtros DEVE exibir a projeção contextual com slider de grau da modalidade ativa, localização unificada (setores e grupos), conquistadores e clássicas. O cabeçalho do Bottom Sheet DEVE conter o botão "Limpar" (que redefine todos os filtros e restaura a ordenação para o padrão) e o botão de feedback in-app na extrema direita, associando o nó `ControlesNode` à árvore de navegação.

#### Scenario: Compartilhamento de critérios comuns entre abas
- **WHEN** o usuário seleciona um conquistador específico na aba "Setores" através do modal de Controles
- **AND** alterna para a aba "Esportivas"
- **THEN** o filtro de conquistador permanece ativo com o mesmo valor selecionado
- **AND** a lista de vias exibe apenas as vias esportivas daquele conquistador.

#### Scenario: Desativação de modalidade na aba Setores
- **WHEN** o usuário desmarca uma modalidade (ex: "Boulder") no modal de Controles da aba "Setores"
- **THEN** os setores que possuem exclusivamente aquela modalidade são omitidos da lista de setores.

#### Scenario: Visualização em linha única com scroll horizontal
- **WHEN** o usuário aplica múltiplos filtros e uma ordenação personalizada
- **THEN** a barra de controles na página acomoda os chips ativos em uma linha única rolável horizontalmente
- **AND** nenhum chip causa quebra para uma segunda linha vertical.

#### Scenario: Ação do botão Limpar no modal de Controles
- **WHEN** o usuário toca no botão "Limpar" dentro do Bottom Sheet de Controles
- **THEN** todos os filtros ativos são redefinidos
- **AND** o modo de ordenação é restaurado para "PADRÃO" com direção crescente (▲).

#### Scenario: Rastreamento de navegação e feedback in-app no modal
- **WHEN** o usuário abre o Modal Bottom Sheet de Controles
- **THEN** o sistema adiciona o nó `ControlesNode` à árvore de navegação ativa
- **AND** tocar no botão de feedback na extrema direita do cabeçalho abre o formulário de feedback com o caminho `Pico -> Setores -> Controles` (ou `Pico -> Grupo -> Controles`).

### Requirement: Ocultação e Enriquecimento de Setores Filtrados
Na aba "Setores", o sistema DEVE (MUST) ocultar setores que não contenham nenhuma escalada correspondente aos filtros ativos e DEVE enriquecer o cartão de cada setor exibindo a faixa de graduação das vias e a quantidade de vias que atendem ao filtro em relação ao total.

#### Scenario: Setor sem vias correspondentes ao filtro
- **WHEN** o usuário filtra por um grau elevado inexistente em determinado setor
- **THEN** esse setor não é exibido na lista de setores.

#### Scenario: Exibição de faixa e contagem no cartão do setor
- **WHEN** o setor possui vias que atendem aos filtros aplicados
- **THEN** o cartão do setor exibe a faixa de graus (ex: "5º a 8a") e o contador de vias correspondentes (ex: "3 vias no filtro (de 10)").

### Requirement: Tríade Padronizada de Ordenação e Direção
A ordenação de setores e escaladas DEVE (MUST) ser integrada à seção "Ordenação" do Modal Bottom Sheet de Controles, apresentando as opções "PADRÃO", "GRAU" e "ALFABÉTICO", acompanhadas do alternador de direção (▲ crescente / ▼ decrescente). Quando a ordenação ativa for diferente do padrão ("PADRÃO" crescente), a barra externa na página DEVE renderizar um chip dinâmico indicando o modo e direção ativos com ícone de remoção rápida (`✕`) para restaurar o padrão.

#### Scenario: Alternância de direção da ordenação
- **WHEN** o usuário toca no botão de alternância de direção de ordenação
- **THEN** o ícone do botão muda (entre seta para cima e seta para baixo)
- **AND** a ordem dos itens exibidos é imediatamente invertida.

#### Scenario: Restauração da ordenação padrão via chip externo
- **WHEN** a listagem está ordenada por "GRAU" (ou qualquer critério não-padrão) e exibe o chip "Grau ▲ ✕"
- **AND** o usuário toca no botão `✕` do chip de ordenação na página externa
- **THEN** a ordenação é imediatamente restaurada para "PADRÃO" crescente
- **AND** o chip de ordenação é removido da barra externa.

### Requirement: Ordenação por Grau com Mediana em Setores
Ao selecionar o modo "GRAU", o sistema DEVE (MUST) ordenar a lista de escaladas pela dificuldade individual da via e a lista de setores pela mediana normalizada dos graus das vias pertencentes a cada setor, utilizando uma escala de peso unificada para equalizar modalidades distintas.

#### Scenario: Ordenação de setores por mediana de grau crescente
- **WHEN** o usuário seleciona a ordenação por "GRAU" com direção crescente na aba "Setores"
- **THEN** os setores cuja mediana das graduações é mais branda aparecem no topo da listagem.

#### Scenario: Ordenação de vias por grau
- **WHEN** o usuário seleciona a ordenação por "GRAU" na aba de uma modalidade
- **THEN** as vias são ordenadas por seu grau de dificuldade conforme a direção selecionada.
