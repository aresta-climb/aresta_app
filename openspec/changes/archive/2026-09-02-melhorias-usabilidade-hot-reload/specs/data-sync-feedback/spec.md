## MODIFIED Requirements

### Requirement: Feedback Contextual de Sincronização
O sistema MUST informar visualmente ao usuário o resultado preciso da verificação de atualizações no servidor, diferenciando sincronizações manuais/explícitas, automáticas de abertura em produção e eventos em tempo real no modo experimental.

#### Scenario: Sincronização explícita encontrou novos dados
- **WHEN** o usuário aciona manualmente a sincronização (via botão nas configurações ou scroll para baixo / *pull-to-refresh* na Home) e novos dados são recebidos (HTTP 200)
- **THEN** a interface de usuário DEVE exibir um feedback indicando que os croquis foram atualizados

#### Scenario: Sincronização explícita sem novos dados
- **WHEN** o usuário aciona manualmente a sincronização (via botão nas configurações ou scroll para baixo / *pull-to-refresh* na Home) e não existem novos dados (HTTP 304)
- **THEN** a interface de usuário DEVE exibir um feedback indicando que nenhum croqui precisava ser atualizado

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
