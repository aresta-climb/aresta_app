## ADDED Requirements

### Requirement: Unified Map Navigation
O aplicativo DEVE (SHALL) unificar a navegação e exibição de mapas de entidades usando um mecanismo único que lida de forma elegante com mapas únicos ou múltiplos, sem a necessidade de intervenção de quem chama a função. O roteamento externo direto para um mapa único fica estritamente proibido em nível de API.

#### Scenario: Navigating to an entity with a single map
- **WHEN** o aplicativo solicita a abertura de mapas para uma entidade (Pico, Grupo, Setor) que possui exatamente um mapa via `AppNav.toMapas`
- **THEN** a UI exibe o `MapaInterativoPage` de forma transparente, sem nenhum componente de UI de carrossel (por exemplo, sem setas ou pontos de paginação)

#### Scenario: Navigating to an entity with multiple maps
- **WHEN** o aplicativo solicita a abertura de mapas para uma entidade que possui múltiplos mapas via `AppNav.toMapas`
- **THEN** a UI exibe o `MapasCarrosselPage` com sua funcionalidade completa de carrossel deslizante e controles de paginação

#### Scenario: Navigating 'Up' from a child map
- **WHEN** um usuário está visualizando um mapa (ex: Setor) e clica no botão "Up" para visualizar a entidade pai (ex: Grupo)
- **THEN** o aplicativo utiliza o mecanismo de navegação unificado de mapas para abrir todos os mapas disponíveis para aquela entidade pai

#### Scenario: Enforcing Unified Map Routing
- **WHEN** um desenvolvedor tenta navegar diretamente para o mapa interativo usando a API de navegação (`AppNav`)
- **THEN** a operação falha em tempo de compilação ou não está disponível, pois o `AppNav.toMapaInterativo` foi removido em favor do `AppNav.toMapas` (que aceita 1 a N mapas).

### Requirement: Code Quality and Testing
O aplicativo DEVE (SHALL) implementar todas as abstrações de navegação usando TDD estrito, garantindo alta qualidade e robustez.

#### Scenario: Ensuring TDD and Coverage
- **WHEN** o código da navegação unificada de mapas for enviado (pushed)
- **THEN** ele deve possuir 100% de cobertura de testes unitários para abstrações novas ou amplamente modificadas (ex: MapHierarchyResolver, AppNav.toMapas).
- **THEN** todos os métodos, classes e propriedades novos e modificados devem conter docstrings atualizados e descritivos.
