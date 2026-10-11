# Spec Delta

## ADDED Requirements

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
