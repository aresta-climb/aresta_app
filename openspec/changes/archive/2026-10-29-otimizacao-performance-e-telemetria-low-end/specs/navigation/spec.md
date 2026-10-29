## ADDED Requirements

### Requirement: Preservação de Instâncias de Páginas e ViewModels na Pilha Declarativa
O controlador de navegação em árvore (`TreeNavigationWrapper`) DEVE (MUST) preservar e reutilizar as instâncias de `Page` e seus respectivos ViewModels para nós que permanecem inalterados na pilha de rotas durante transições de navegação (push ou pop), evitando reconstruções e reinstanciações de rotas subjacentes.

#### Scenario: Empilhamento de nova página sobre a página do Pico
- **WHEN** o usuário está na página de detalhes do Pico (`PicoNode`) e navega para um Setor (`SetorNode`), Via (`ViaNode`) ou Mapa (`MapasCarrosselNode`)
- **THEN** a `Page` e o `PicoViewModel` correspondentes ao `PicoNode` subjacente são reutilizados na lista declarativa do `Navigator` sem reinstanciação durante a animação de transição

### Requirement: Injeção do DatasetResolver Compartilhado no Construtor Reativo de Página
O `PageListenableBuilder` DEVE (MUST) resolver e disponibilizar a instância compartilhada do `DatasetResolver` do croqui ativo para as páginas filhas da hierarquia, garantindo acesso imediato O(1) às entidades resolvidas durante a transição de rota.

#### Scenario: Construção de página de Setor, Via ou Mapa via PageListenableBuilder
- **WHEN** o `PageListenableBuilder` constrói uma página contextualizada a um croqui
- **THEN** ele obtém a instância cacheada de `DatasetResolver` do `Pico`/`Croqui` atual e resolve o setor, grupo e escalada sem reindexar o pico
