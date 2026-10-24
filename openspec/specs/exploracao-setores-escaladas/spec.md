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
O sistema DEVE (MUST) disponibilizar um card unificado de "Filtros e Ordenação" na página de exploração que aciona um Modal Bottom Sheet reativo com estado global compartilhado. Na linha superior do card, o botão de abertura DEVE ser 100% clicável em toda a sua extensão horizontal com efeito tátil uniforme. Quando houver filtros ativos ou ordenação não-padrão, os chips com remoção rápida (`✕`) DEVEM ser exibidos na linha inferior dentro do mesmo card, distribuídos confortavelmente com quebra de linha fluida (`Wrap`) ocupando a largura total sem rolagem lateral comprimida. O Modal Bottom Sheet DEVE ser empilhado no navegador raiz (`useRootNavigator: true`), assegurando que o botão voltar do sistema operacional feche o modal no primeiro toque sem afetar a página subjacente. O Modal Bottom Sheet DEVE conter duas seções distintas: "Ordenação" e "Filtros". A seção de filtros DEVE disponibilizar sliders de grau com régua adaptativa recortada conforme a amplitude real dos graus das escaladas cadastradas para a modalidade ativa (ou para cada categoria no modo superset). Na aba "Setores", a seção de filtros DEVE exibir o superset com modalidades ativas, réguas adaptativas específicas para cada categoria (Vias e Boulders), grupos, conquistadores e vias clássicas. Nas abas de modalidade, a seção de filtros DEVE exibir a projeção contextual com régua adaptativa da modalidade ativa, localização unificada (setores e grupos), conquistadores e clássicas. Os menus suspensos (`DropdownButton`) de seleção de localização e de conquistadores DEVEM ter altura máxima restrita (`menuMaxHeight: 280`), garantindo que nunca ocupem a tela inteira em picos com muitos itens e sempre deixem área livre para toque externo de cancelamento. O cabeçalho do Bottom Sheet DEVE conter o botão "Limpar" (que redefine todos os filtros e restaura a ordenação para o padrão) e o botão de feedback in-app na extrema direita, associando o nó `ControlesNode` à árvore de navegação. O rodapé do Bottom Sheet DEVE exibir um botão de confirmação de largura total com rótulo dinâmico `Aplicar (X resultados)` (ou `Aplicar (1 resultado)` no singular, ou `Aplicar` quando o contador não for informado) que fecha o modal mantendo a aplicação reativa e imediata em tempo real (assim como fechar pelo `✕`, tocar fora ou acionar o botão voltar).

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
- **THEN** o card unificado renderiza o botão "Filtros e Ordenação" na linha superior com 100% de largura
- **AND** renderiza os chips ativos logo abaixo em um layout com quebra de linha fluida (`Wrap`)
- **AND** nenhum chip é cortado na borda ou restrito a scroll horizontal comprimido.

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
- **WHEN** o card externo exibe chips ativos na área inferior
- **AND** o usuário toca no cabeçalho ou no espaço ao redor dos chips
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

#### Scenario: Fechamento imediato do modal com botão voltar do sistema
- **WHEN** o Modal Bottom Sheet de controles está visível sobre uma página de exploração (Pico, Grupo ou Setor)
- **AND** o usuário aciona o botão ou gesto de voltar nativo do sistema operacional (Android Back)
- **THEN** o modal é fechado imediatamente na primeira invocação
- **AND** a página de exploração subjacente permanece aberta e ativa sem efeito cascata.

#### Scenario: Limite de altura nos seletores de localização e conquistadores
- **WHEN** o usuário toca no seletor de "Conquista (Autores)" ou de "Localização" em um pico com dezenas de opções disponíveis
- **THEN** o menu suspenso é exibido com altura máxima limitada (`menuMaxHeight: 280`) sem cobrir a totalidade da tela
- **AND** o usuário consegue tocar na área externa ao menu suspenso para fechá-lo sem ser obrigado a selecionar um item.

#### Scenario: Confirmação e feedback reativo no botão Aplicar do rodapé
- **WHEN** o Modal Bottom Sheet de controles está aberto e o usuário altera critérios de filtragem
- **THEN** o botão no rodapé do modal atualiza seu rótulo em tempo real exibindo `Aplicar (X resultados)` (ou `Aplicar (1 resultado)` quando houver exatamente 1 item)
- **AND** tocar no botão `Aplicar (X resultados)` fecha o modal mantendo todos os filtros aplicados, da mesma forma que fechar pelo `✕`, tocar fora ou usar o gesto/botão de voltar.

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

### Requirement: Exploração de Escaladas no Setor com Filtros Unificados
A página de setor (`SetorPage`) DEVE (MUST) unificar a visualização de escaladas conectando-se ao estado global de filtros e ordenação do pico. Quando o setor possuir múltiplas modalidades, o sistema DEVE ordenar as abas por volume decrescente de vias (selecionando a mais volumosa por padrão) e ocultar a barra de abas se houver apenas uma modalidade. O sistema DEVE exibir o `PainelFiltrosIndice` adaptado ao setor e renderizar cards de escalada com o rótulo do croqui à esquerda e grau no subtítulo.

#### Scenario: Setor com múltiplas modalidades ordenadas por volume
- **WHEN** o usuário abre a página de um setor com 10 vias esportivas e 3 boulders
- **THEN** as abas são exibidas na ordem "Esportivas (10)" e "Boulders (3)"
- **AND** a aba "Esportivas" é aberta inicialmente por padrão
- **AND** nenhuma aba agregadora "Todas" é exibida.

#### Scenario: Setor com modalidade única oculta barra de abas
- **WHEN** o usuário abre a página de um setor que possui apenas vias de uma única modalidade (ex: 8 vias esportivas)
- **THEN** a barra de abas de modalidade é ocultada da interface
- **AND** a lista de vias esportivas é renderizada diretamente abaixo dos filtros.

#### Scenario: Herança e sincronização de filtros globais no setor
- **WHEN** o usuário define filtros de grau ou ordenação na página do pico e entra em um setor
- **THEN** a página do setor exibe as escaladas filtradas e ordenadas segundo esses mesmos critérios
- **AND** a barra de filtros reflete os chips ativos
- **AND** alterações de filtros no setor são sincronizadas com o estado global do croqui.

#### Scenario: Card de escalada com rótulo do croqui e grau no subtítulo
- **WHEN** uma escalada do setor é renderizada na lista
- **THEN** o card exibe no badge à esquerda o número ou indicador de referência no croqui
- **AND** exibe o grau e proteções no subtítulo técnico abaixo do nome da via.

#### Scenario: Abertura contextual e rolagem para scrollToEscalada
- **WHEN** a página de setor é aberta informando uma escalada alvo (`scrollToEscalada`) pertencente a uma modalidade secundária (ex: Boulder)
- **THEN** a aba daquela modalidade é selecionada automaticamente
- **AND** a tela rola até o card da escalada aplicando o efeito de realce pulsante.
