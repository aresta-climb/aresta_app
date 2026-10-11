# Spec Delta

## MODIFIED Requirements

### Requirement: Painel de Filtros Reativo e Superset
O sistema DEVE (MUST) disponibilizar uma barra de "Filtros e Ordenação" na página de exploração que aciona um Modal Bottom Sheet reativo com estado global compartilhado. Na página principal, quando não houver filtros ativos, a barra DEVE ser 100% clicável em toda a sua extensão horizontal com efeito tátil uniforme. Quando houver filtros ativos, a barra DEVE exibir o botão de abertura à esquerda e uma trilha de chips em linha única com rolagem horizontal (scroll horizontal), contendo chips com remoção rápida (`✕`) para filtros ativos e para ordenação não-padrão, permitindo que toques no espaço vazio à direita dos chips também abram o modal. O Modal Bottom Sheet DEVE conter duas seções distintas: "Ordenação" e "Filtros". A seção de filtros DEVE disponibilizar sliders de grau com régua adaptativa recortada conforme a amplitude real dos graus das escaladas cadastradas para a modalidade ativa (ou para cada categoria no modo superset). Na aba "Setores", a seção de filtros DEVE exibir o superset com modalidades ativas, réguas adaptativas específicas para cada categoria (Vias e Boulders), grupos, conquistadores e vias clássicas. Nas abas de modalidade, a seção de filtros DEVE exibir a projeção contextual com régua adaptativa da modalidade ativa, localização unificada (setores e grupos), conquistadores e clássicas. O cabeçalho do Bottom Sheet DEVE conter o botão "Limpar" (que redefine todos os filtros e restaura a ordenação para o padrão) e o botão de feedback in-app na extrema direita, associando o nó `ControlesNode` à árvore de navegação.

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

#### Scenario: Barra externa sem filtros é 100% clicável
- **WHEN** o usuário visualiza a página de exploração sem filtros ativos
- **AND** toca em qualquer ponto da barra externa (inclusive no centro ou na extrema direita)
- **THEN** o sistema aciona a abertura do Modal Bottom Sheet de filtros e ordenação
- **AND** exibe o efeito visual de ondulação (ripple) por toda a extensão da barra.

#### Scenario: Toque no espaço vazio dos chips abre o modal
- **WHEN** a barra externa exibe chips ativos que não preenchem toda a largura da tela
- **AND** o usuário toca no espaço vazio à direita do último chip
- **THEN** o sistema abre o Modal Bottom Sheet de filtros e ordenação
- **AND** os botões de remoção rápida (✕) dos chips continuam funcionando independentemente.

#### Scenario: Régua adaptativa de grau baseada nas escaladas do pico
- **WHEN** o usuário abre o modal de filtros em um pico cujas vias variam entre 4º e 9a
- **THEN** o slider de faixa de grau de vias tem como limite mínimo exatamente 4º e limite máximo 9a
- **AND** o badge superior indica a amplitude total (ex: "Todos os graus (4º a 9a)") quando nenhuma restrição de grau estiver aplicada.

#### Scenario: Pico com grau único expande régua para estabilidade
- **WHEN** o usuário abre o modal de filtros em um setor ou pico onde todas as escaladas possuem o mesmo grau (ex: 6º)
- **THEN** o sistema expande a régua com margem de segurança de ±1 grau vizinho
- **AND** o RangeSlider permanece interativo e operável sem erros.
