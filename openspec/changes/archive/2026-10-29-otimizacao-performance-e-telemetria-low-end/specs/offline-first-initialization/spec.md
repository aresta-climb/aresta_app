## ADDED Requirements

### Requirement: Carregamento Sob Demanda de Croquis Baixados na Inicialização
O sistema DEVE (MUST) inicializar o catálogo de picos disponíveis e baixados utilizando exclusivamente os metadados leves do `indice.binarypb` e `catalogo.db`, sem ler do disco nem desserializar arquivos `compilado.binarypb` durante o bootstrap ou atualização do índice. A leitura e desserialização de um `compilado.binarypb` DEVE ocorrer sob demanda apenas quando o croqui específico for requisitado para visualização.

#### Scenario: Inicialização com múltiplos croquis baixados localmente
- **WHEN** o usuário abre o aplicativo possuindo múltiplos croquis salvos em `/downloads/<picoId>/compilado.binarypb`
- **THEN** o sistema verifica a existência física dos diretórios/arquivos e popula `picosBaixados` com os metadados do índice sem desserializar os binários `compilado.binarypb` no bootstrap
- **AND** o `compilado.binarypb` de um pico só é lido e desserializado quando o usuário navega para o pico correspondente

### Requirement: Montagem Sob Demanda de Abas Secundárias na Navegação Principal
O sistema DEVE (MUST) construir no primeiro frame da aplicação apenas a aba inicialmente ativa da navegação principal (`HomePage`), postergando a instanciação dos widgets das demais abas do `IndexedStack` (`BrowsePage`, `MeusCroquisPage` e `ComunidadePage`) até que o usuário selecione a respectiva aba pela primeira vez.

#### Scenario: Primeiro frame no Cold Start direcionado à Home
- **WHEN** o aplicativo conclui o bootstrap e monta o `TreeNavigationWrapper` na aba inicial (`HomeNode`)
- **THEN** apenas a `HomePage` é construída no primeiro frame, mantendo placeholders leves nas abas ainda não visitadas
- **AND** quando o usuário toca em uma aba secundária pela primeira vez, seu widget é construído e passa a ser preservado no `IndexedStack`
