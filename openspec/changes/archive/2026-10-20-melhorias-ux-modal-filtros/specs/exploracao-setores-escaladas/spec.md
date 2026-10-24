## MODIFIED Requirements

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
