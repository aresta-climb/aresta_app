# data-sync-feedback Specification

## Purpose
Define o comportamento visual, notificações e telemetria de sincronização de dados entre o aplicativo e os servidores de catálogo (produção oficial e modo experimental).

## Requirements

### Requirement: Feedback Contextual de Sincronização
O sistema MUST informar visualmente ao usuário o resultado preciso da verificação de atualizações no servidor, diferenciando sincronizações manuais/explícitas, automáticas de abertura em produção, eventos em tempo real no modo experimental, falhas de conectividade (`SyncStatus.offline`) e erros HTTP do servidor (`SyncStatus.error`).

#### Scenario: Sincronização explícita encontrou novos dados
- **WHEN** o usuário aciona manualmente a sincronização (via botão nas configurações ou scroll para baixo / *pull-to-refresh* na Home) e novos dados são recebidos (HTTP 200)
- **THEN** a interface de usuário DEVE exibir um feedback indicando que os croquis foram atualizados

#### Scenario: Sincronização explícita sem novos dados
- **WHEN** o usuário aciona manualmente a sincronização (via botão nas configurações ou scroll para baixo / *pull-to-refresh* na Home) e não existem novos dados (HTTP 304)
- **THEN** a interface de usuário DEVE exibir um feedback indicando que nenhum croqui precisava ser atualizado

#### Scenario: Sincronização explícita falha por falta de conexão com a internet
- **WHEN** o usuário aciona manualmente a sincronização e `fetchIndiceWithRetries` retorna `IndiceOffline` (falha de socket/timeout)
- **THEN** o `SyncService` DEVE definir `syncStatus` como `SyncStatus.offline`
- **AND** a interface de usuário DEVE exibir a SnackBar `"Sem conexão com a internet."`

#### Scenario: Sincronização explícita falha por erro HTTP do servidor oficial
- **WHEN** o usuário aciona manualmente a sincronização no Modo Oficial e `fetchIndiceWithRetries` retorna `IndiceErroServidor` (ex: HTTP 500 ou 404 na CDN oficial)
- **THEN** o `SyncService` DEVE definir `syncStatus` como `SyncStatus.error`
- **AND** a interface de usuário DEVE exibir a SnackBar `"Erro ao verificar atualizações. Tente novamente mais tarde."`

#### Scenario: Sincronização explícita detecta sessão experimental expirada (HTTP 404)
- **WHEN** o usuário aciona manualmente a sincronização enquanto estava no Modo Experimental e a sessão de prévia é encerrada automaticamente por `HTTP 404`
- **THEN** a função de sincronização manual NÃO DEVE exibir SnackBar de erro ou de falta de conexão, deixando apenas o diálogo modal de encerramento da sessão experimental visível na tela

#### Scenario: Sincronização automática de abertura com atualização de croquis baixados em produção
- **WHEN** o aplicativo realiza sincronização automática na inicialização no modo oficial e um ou mais croquis armazenados localmente são atualizados
- **THEN** a interface de usuário DEVE aplicar as atualizações na memória e exibir um toast informativo discreto indicando que o croqui foi atualizado para a versão mais recente

#### Scenario: Sincronização em modo experimental não exibe snackbars textuais
- **WHEN** o aplicativo realiza sincronização ou recebe evento de Hot Reload em modo experimental
- **THEN** a interface de usuário NÃO DEVE exibir SnackBars ou alertas textuais interruptivos de sincronização
- **AND** a interface DEVE acionar a atualização em tela acompanhada de um pulso luminoso no banner superior

#### Scenario: Sincronização automática de abertura sem alteração em croquis baixados
- **WHEN** o aplicativo realiza sincronização automática na inicialização e nenhum croqui armazenado localmente foi atualizado (seja por HTTP 304 ou por alterações exclusivas do catálogo geral)
- **THEN** a interface de usuário NÃO DEVE exibir notificação de atualização

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

### Requirement: Código e Documentação em Português Brasileiro
Todo o código, nomes de variáveis, métodos, comentários e documentações MUST ser redigidos em português brasileiro, acompanhados de docstrings explicativas e atualização dos arquivos README.md.

#### Scenario: Nomenclatura e Documentação no Código
- **WHEN** novos identificadores ou membros de classe forem criados
- **THEN** os nomes DEVEM estar em português brasileiro (ex: `quantidadeCroquisBaixadosAtualizadosNoUltimoSync`)
- **AND** métodos e propriedades DEVEM conter docstrings (`///`) em português explicando a intenção
- **AND** os arquivos `README.md` pertinentes DEVEM ser atualizados para refletir a nova funcionalidade
