## Why

A sincronização em segundo plano do Aresta é rápida e atômica, garantindo que croquis salvos sejam mantidos em dia. No entanto, quando o aplicativo é aberto e realiza a sincronização automática de inicialização, atualizando silenciosamente os croquis baixados pelo escalador, o usuário não recebe nenhuma indicação visual de que seus croquis offline receberam correções ou novos dados.

Ao mesmo tempo, não queremos poluir a interface exibindo avisos quando nada mudou ou quando apenas o catálogo remoto sofreu alterações irrelevantes para o armazenamento offline do usuário. Notificar o usuário exclusivamente quando **croquis baixados** forem atualizados na abertura do aplicativo traz transparência, valor e sensação de confiabilidade ("offline-first"), sem gerar ruído desnecessário no uso cotidiano.

Em contrapartida, quando o usuário solicita explicitamente a sincronização (seja clicando no botão "Sincronizar" nas Configurações ou fazendo scroll para baixo / *pull-to-refresh* na Home), o comportamento atual de feedback explícito é mantido intacto para todos os estados (avisando tanto quando atualizou quanto quando não havia atualizações).

## What Changes

- O `SyncService` passará a rastrear e expor explicitamente em português (`quantidadeCroquisBaixadosAtualizadosNoUltimoSync`) se a última sincronização resultou em atualizações efetivas em **croquis baixados** (armazenados localmente).
- O listener de sincronização em `TreeNavigationWrapper` (`main.dart`) passará a exibir uma SnackBar informativa (`"Seus croquis baixados foram atualizados!"`) quando uma sincronização **automática de abertura** (`lastSyncWasAuto == true`) concluir com sucesso a atualização de um ou mais croquis locais.
- Se a sincronização automática de abertura resultar apenas em atualizações do catálogo/índice geral (sem impacto nos croquis baixados) ou não tiver atualizações (HTTP 304), a interface permanecerá em silêncio absoluto.
- O comportamento existente de feedback da sincronização manual acionada pelo usuário (via botão nas configurações ou via *pull-to-refresh* / scroll para baixo na Home) permanece **100% inalterado**, continuando a exibir o aviso de status completo (incluindo "Nenhum croqui precisava ser atualizado" e "Croquis foram atualizados!").
- Todo o código, métodos, variáveis, testes e comentários serão estritamente em português brasileiro, com docstrings explicativas e 100% de cobertura de testes.

## Capabilities

### Modified Capabilities
- `data-sync-feedback`: Adiciona requisitos e cenários para a diferenciação de feedback entre sincronizações automáticas de abertura (notificação apenas se croquis baixados forem alterados) e sincronizações manuais/explícitas (botão ou pull-to-refresh, que continuam reportando todos os estados).

## Impact

- `frontend/lib/services/http/sync_service.dart`: Rastreamento e exposição da contagem de croquis baixados atualizados.
- `frontend/lib/main.dart` (`TreeNavigationWrapper`): Listener de estado para exibir SnackBar na abertura do app quando `lastSyncWasAuto == true` e houver croquis locais baixados atualizados.
- `frontend/lib/README.md` e `frontend/lib/services/README.md`: Atualização da documentação sobre o fluxo reativo e notificações de sincronização.
- Testes de widget e unitários em `frontend/test/` cobrindo 100% das alterações.
