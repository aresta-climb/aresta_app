## ADDED Requirements

### Requirement: Sincronização Reativa entre Grau e Modalidade na Aba Setores
Na aba "Setores", o sistema DEVE (MUST) manter todas as réguas de categoria de grau disponíveis no local ("Vias" e "Boulders") sempre renderizadas e sincronizar automaticamente os chips de modalidade quando o usuário restringir ou limpar uma faixa de grau, esmaecendo a régua da categoria inativa e exibindo na barra externa apenas o chip da faixa de grau quando a restrição de modalidade for derivada automaticamente do grau.

#### Scenario: Restrição de grau de vias desmarca boulders e esmaece régua de boulders
- **WHEN** o usuário está em um local com vias e boulders sem restrições prévias e ajusta a régua "Faixa de Grau (Vias)" para um intervalo restrito (ex: 7a a 8a)
- **THEN** o chip de modalidade "Boulder" é desmarcado automaticamente no modal
- **AND** a régua "Faixa de Grau (Boulders)" permanece visível na tela em estado esmaecido indicando modalidade inativa (sem salto de layout)
- **AND** a barra externa exibe apenas o chip "Vias: 7a a 8a ✕" (contabilizando 1 filtro ativo, sem exibir chips extras de modalidade).

#### Scenario: Interação com régua esmaecida reativa a modalidade automaticamente
- **WHEN** a categoria "Boulder" está desmarcada e com régua esmaecida devido a um filtro de grau em "Vias" (ex: 7a a 8a)
- **AND** o usuário arrasta a régua esmaecida de "Faixa de Grau (Boulders)" para definir um intervalo (ex: V2 a V4)
- **THEN** o sistema reativa automaticamente a modalidade "Boulder" nos chips de modalidade mantendo as modalidades de "Via" ativas
- **AND** ambas as faixas de grau ("Vias: 7a a 8a" e "Boulders: V2 a V4") passam a filtrar conjuntamente a aba "Setores".

#### Scenario: Limpeza do filtro de grau em 1 clique restaura modalidades sincronizadas
- **WHEN** a modalidade "Boulder" foi desmarcada automaticamente em razão de um filtro de grau de vias ("Vias: 7a a 8a")
- **AND** o usuário toca no botão `✕` do chip externo "Vias: 7a a 8a ✕" (ou retorna a régua de vias para "Todos os graus")
- **THEN** o filtro de grau de vias é removido
- **AND** todas as modalidades voltam a ficar ativas automaticamente, restaurando a exibição dos setores e badges de boulders.

### Requirement: Isolamento de Filtros de Grau e Modalidade nas Abas Específicas
Nas abas dedicadas a uma modalidade específica (ex: "Esportivas", "Boulders", "Móveis", "Multienfiadas"), o sistema DEVE (MUST) ignorar o filtro de modalidades ativas da aba "Setores" e ignorar filtros de faixa de grau pertencentes a outra categoria de graduação, aplicando apenas a faixa de grau da própria categoria e os filtros transversais (localização, conquistador, clássicas, busca e ordenação).

#### Scenario: Aba Boulders ignora filtro de grau de vias
- **WHEN** o usuário aplica um filtro de grau de vias (ex: 7a a 8a) na aba "Setores" ou na aba "Esportivas"
- **THEN** a aba "Setores" oculta os boulders nos cards dos setores e oculta setores exclusivos de boulder
- **AND** o rótulo da aba "Boulders" mantém o contador limpo `Boulders (total)` (sem exibir `(0/total)` ou `(total/total)`)
- **AND** ao tocar na aba "Boulders", todas as escaladas de boulder são listadas normalmente.

#### Scenario: Aba Esportivas ignora filtro de grau de boulders
- **WHEN** o usuário aplica um filtro de grau de boulders (ex: V3 a V5) sem outros filtros transversais ativos
- **THEN** a aba "Setores" exibe apenas setores com boulders entre V3 e V5 e oculta as vias nos cards de setores
- **AND** o rótulo da aba "Esportivas" mantém o contador limpo `Esportivas (total)`
- **AND** ao tocar na aba "Esportivas", todas as vias esportivas são listadas normalmente.

## MODIFIED Requirements

### Requirement: Abas Dinâmicas de Exploração com Contadores
A página de exploração DEVE (MUST) renderizar uma barra de abas onde a primeira aba é "Setores" e as abas subsequentes representam cada modalidade de escalada existente no pico (ex: "Esportivas", "Boulders", "Móveis"). A aba "Setores" DEVE exibir o contador `(total)` quando não houver filtros ativos ou `(filtrados/total)` quando houver qualquer filtro ativo. Cada aba de modalidade DEVE exibir `(total)` quando não houver filtros ativos aplicáveis àquela modalidade específica, ou `(filtradas/total)` quando houver ao menos um filtro aplicável àquela modalidade (grau da própria categoria, localização, conquistador, clássicas ou busca).

#### Scenario: Pico com múltiplas modalidades sem filtros
- **WHEN** o usuário abre a exploração de um pico com 13 setores, 95 vias esportivas e 40 boulders sem filtros
- **THEN** as abas exibem exatamente "Setores (13)", "Esportivas (95)" e "Boulders (40)".

#### Scenario: Contadores atualizados dinamicamente após filtragem
- **WHEN** o usuário define apenas um filtro de grau de via que restringe o resultado para 4 setores e 12 vias esportivas
- **THEN** as abas passam a exibir imediatamente "Setores (4/13)", "Esportivas (12/95)" e "Boulders (40)".

#### Scenario: Contadores atualizados após filtro transversal compartilhado
- **WHEN** o usuário ativa o filtro "Apenas Clássicas (★)" que restringe para 5 setores, 10 vias esportivas e 4 boulders
- **THEN** as abas passam a exibir "Setores (5/13)", "Esportivas (10/95)" e "Boulders (4/40)".

### Requirement: Exploração de Escaladas no Setor com Filtros Unificados
A página de setor (`SetorPage`) DEVE (MUST) unificar a visualização de escaladas conectando-se ao estado global de filtros e ordenação do pico, avaliando em cada aba de modalidade apenas os filtros aplicáveis àquela modalidade (grau da própria categoria e filtros transversais) e ignorando restrições de modalidade ou de grau de outras categorias. Quando o setor possuir múltiplas modalidades, o sistema DEVE ordenar as abas por volume decrescente de vias (selecionando a mais volumosa por padrão) e ocultar a barra de abas se houver apenas uma modalidade. O sistema DEVE exibir o `PainelFiltrosIndice` adaptado ao setor e renderizar cards de escalada com o rótulo do croqui à esquerda e grau no subtítulo.

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
- **WHEN** o usuário define um filtro de grau de vias na página do pico e entra em um setor misto (que possui vias esportivas e boulders)
- **THEN** a aba "Esportivas" do setor exibe as vias filtradas segundo o grau de via e a barra de filtros reflete o chip ativo
- **AND** se o usuário alternar para a aba "Boulders" do setor, os boulders do setor são exibidos normalmente ignorando o filtro de grau de via
- **AND** alterações de filtros no setor são sincronizadas com o estado global do croqui.

#### Scenario: Card de escalada com rótulo do croqui e grau no subtítulo
- **WHEN** uma escalada do setor é renderizada na lista
- **THEN** o card exibe no badge à esquerda o número ou indicador de referência no croqui
- **AND** exibe o grau e proteções no subtítulo técnico abaixo do nome da via.

#### Scenario: Abertura contextual e rolagem para scrollToEscalada
- **WHEN** a página de setor é aberta informando uma escalada alvo (`scrollToEscalada`) pertencente a uma modalidade secundária (ex: Boulder)
- **THEN** a aba daquela modalidade é selecionada automaticamente
- **AND** a tela rola até o card da escalada aplicando o efeito de realce pulsante.
