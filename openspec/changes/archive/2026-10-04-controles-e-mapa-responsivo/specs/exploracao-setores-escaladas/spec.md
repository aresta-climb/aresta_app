# Spec Delta: exploracao-setores-escaladas

## MODIFIED Requirements

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
