## MODIFIED Requirements

### Requirement: Feedback Contextual de Sincronização
O sistema MUST informar visualmente ao usuário o resultado preciso da verificação de atualizações no servidor, diferenciando sincronizações manuais/explícitas (botão nas configurações ou *pull-to-refresh* na Home) de sincronizações automáticas de abertura do aplicativo.

#### Scenario: Sincronização explícita encontrou novos dados
- **WHEN** o usuário aciona manualmente a sincronização (via botão nas configurações ou scroll para baixo / *pull-to-refresh* na Home) e novos dados são recebidos (HTTP 200)
- **THEN** a interface de usuário DEVE exibir um feedback indicando "Croquis foram atualizados!"

#### Scenario: Sincronização explícita sem novos dados
- **WHEN** o usuário aciona manualmente a sincronização (via botão nas configurações ou scroll para baixo / *pull-to-refresh* na Home) e não existem novos dados (HTTP 304)
- **THEN** a interface de usuário DEVE exibir um feedback indicando "Nenhum croqui precisava ser atualizado."

#### Scenario: Sincronização automática de abertura com atualização de croquis baixados
- **WHEN** o aplicativo realiza sincronização automática na inicialização e um ou mais croquis armazenados localmente são atualizados
- **THEN** a interface de usuário DEVE exibir uma SnackBar com a mensagem "Seus croquis baixados foram atualizados!"

#### Scenario: Sincronização automática de abertura sem alteração em croquis baixados
- **WHEN** o aplicativo realiza sincronização automática na inicialização e nenhum croqui armazenado localmente foi atualizado (seja por HTTP 304 ou por alterações exclusivas do catálogo geral)
- **THEN** a interface de usuário NÃO DEVE exibir notificação de atualização (silêncio)

#### Scenario: Sincronização automática de abertura com falha
- **WHEN** o aplicativo realiza sincronização automática na inicialização e ocorre falha de conexão/erro
- **THEN** a interface de usuário DEVE exibir uma SnackBar informando o erro

### Requirement: Test Driven Development
O sistema MUST ser desenvolvido utilizando Test-Driven Development (TDD) e priorizar Testes de Widget em primeiro lugar, mantendo 100% de cobertura de testes para os arquivos modificados.

#### Scenario: Testes de Widget e Unitários em Primeiro Lugar
- **WHEN** a lógica de sincronização ou a apresentação visual de status for modificada
- **THEN** os testes de widget e unitários DEVEM ser escritos antes da implementação do código de produção (Red-Green-Refactor)
- **AND** a cobertura de testes para os arquivos modificados DEVE ser 100%

### Requirement: Telemetria de Resultado da Sincronização
O sistema MUST registrar na telemetria o resultado exato do término do fluxo global de sincronização.

#### Scenario: Sincronização com Atualizações
- **WHEN** a sincronização de todos os picos locais finaliza e há atualizações efetivas (status: justUpdated)
- **THEN** o sistema dispara o evento `logResultadoSincronizacao` passando o status 'sucesso'

#### Scenario: Sincronização sem Atualizações (No Updates)
- **WHEN** a sincronização finaliza mas nenhum pacote novo precisou ser baixado (status: noNewUpdates)
- **THEN** o sistema dispara o evento `logResultadoSincronizacao` passando o status 'sem_atualizacoes'

#### Scenario: Falha na Sincronização
- **WHEN** a sincronização global resulta em erro para o usuário (status: error)
- **THEN** o sistema dispara o evento `logResultadoSincronizacao` passando o status 'erro'

## ADDED Requirements

### Requirement: Código e Documentação em Português Brasileiro
Todo o código, nomes de variáveis, métodos, comentários e documentações MUST ser redigidos em português brasileiro, acompanhados de docstrings explicativas e atualização dos arquivos README.md.

#### Scenario: Nomenclatura e Documentação no Código
- **WHEN** novos identificadores ou membros de classe forem criados
- **THEN** os nomes DEVEM estar em português brasileiro (ex: `quantidadeCroquisBaixadosAtualizadosNoUltimoSync`)
- **AND** métodos e propriedades DEVEM conter docstrings (`///`) em português explicando a intenção
- **AND** os arquivos `README.md` pertinentes DEVEM ser atualizados para refletir a nova funcionalidade
