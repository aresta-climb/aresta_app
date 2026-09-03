# hot-reload-experiencia-usuario Specification

## Requirements

### Requirement: Auto-Download e Navegação Pós-Conexão Experimental
O sistema MUST baixar automaticamente os arquivos do croqui e navegar diretamente para a visualização após uma conexão bem-sucedida com o Editor Desktop.

#### Scenario: Pareamento com índice de croqui único
- **WHEN** o aplicativo conclui com sucesso a conexão com o editor desktop e o índice contém exatamente um croqui
- **THEN** o sistema DEVE iniciar e aguardar o download imediato do pacote binário do croqui
- **AND** o sistema DEVE carregar o dataset em memória e navegar a árvore diretamente para o PicoNode do croqui baixado

#### Scenario: Pareamento com índice de múltiplos croquis
- **WHEN** o aplicativo conclui com sucesso a conexão com o editor desktop e o índice contém mais de um croqui
- **THEN** o sistema DEVE navegar para a aba Explorar (BrowseNode) com o banner experimental ativo

### Requirement: Componente Modular e Pulso Luminoso no Banner Experimental
O sistema MUST fornecer um widget independente e modular (BannerModoExperimental) que emita um feedback visual luminoso sutil e não-bloqueante no banner ao receber eventos push de recarregamento, suportando tanto croquis baixados no armazenamento local quanto croquis abertos em sessão online (streaming).

#### Scenario: Recebimento de evento Live Reload para croqui baixado
- **WHEN** o aplicativo recebe uma notificação push WebSocket de recarga do editor desktop para um croqui baixado
- **THEN** o BannerModoExperimental DEVE acionar uma transição de pulso luminoso com duração de até 500ms
- **AND** a tela aberta DEVE ser reconstruída com os novos dados em memória preservando a posição de rolagem.

#### Scenario: Recebimento de evento Live Reload para croqui em sessão online
- **WHEN** o aplicativo recebe uma notificação push WebSocket de recarga e o croqui atualmente aberto na navegação está em sessão online (não baixado)
- **THEN** o sistema DEVE executar re-fetch do arquivo `.binarypb` com parâmetro de quebra de cache HTTP
- **AND** o sistema DEVE atualizar o `GerenciadorSessaoOnline` e reindexar as mídias no `DatasetRepository`
- **AND** o BannerModoExperimental DEVE acionar a transição de pulso luminoso
- **AND** a tela aberta DEVE ser reconstruída de forma seamless com os novos dados em memória preservando a posição de rolagem.

### Requirement: Botão de Desconexão Rápida no Banner Superior
O banner global de modo experimental MUST conter uma ação rápida de encerramento para permitir o retorno imediato à biblioteca oficial de produção.

#### Scenario: Clique no botão de sair do banner
- **WHEN** o usuário toca no botão de fechar/sair presente no banner superior de modo experimental
- **THEN** o sistema DEVE executar a limpeza dos dados experimentais (
ukeExperimentalData)
- **AND** o sistema DEVE resetar a navegação para a tela inicial oficial (HomeNode)

### Requirement: Test Driven Development
O sistema MUST ser desenvolvido utilizando Test-Driven Development (TDD) e priorizar Testes de Widget em primeiro lugar, mantendo 100% de cobertura de testes para os arquivos modificados.

#### Scenario: Testes de Widget e Unitários em Primeiro Lugar
- **WHEN** a lógica de conexão, o widget do banner ou o roteamento forem implementados ou modificados
- **THEN** os testes de widget e unitários DEVEM ser escritos e validados em falha antes do código de produção (Red-Green-Refactor)
- **AND** a cobertura de testes para os arquivos modificados DEVE ser 100%

### Requirement: Código e Documentação em Português Brasileiro
Todo o código, nomes de variáveis, métodos, comentários e documentações MUST ser redigidos em português brasileiro, acompanhados de docstrings explicativas e atualização dos arquivos README.md.

#### Scenario: Nomenclatura e Documentação no Código
- **WHEN** novos componentes, identificadores ou membros forem criados
- **THEN** os nomes DEVEM estar em português brasileiro (ex: BannerModoExperimental, 
otificadorGatilhoRecarregamento)
- **AND** métodos e classes DEVEM conter docstrings (///) em português explicando a intenção
- **AND** os arquivos README.md pertinentes DEVEM ser atualizados para documentar a funcionalidade
