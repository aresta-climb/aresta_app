## Context

O processo de sincronização atual (`SyncService`) notifica a interface de usuário que a sincronização terminou alterando o estado para `SyncStatus.justUpdated`. Atualmente, a UI mapeia esse estado para uma badge de "Foram atualizados!", independentemente de o servidor ter retornado novos dados (HTTP 200) ou de não haver nenhuma mudança desde a última sincronização (HTTP 304 - Not Modified). 

Esse comportamento gera confusão para o usuário, que recebe um feedback de que algo mudou quando, na verdade, os dados já estavam atualizados na sua versão mais recente.

## Goals / Non-Goals

**Goals:**
- Diferenciar os estados pós-sincronização baseando-se no retorno do servidor (HTTP 200 vs 304).
- Fornecer um feedback claro ("Já está atualizado" ou "Sem atualizações") quando não houver novos dados, distinto de quando realmente algo foi modificado.
- Manter o timer existente que faz o status de `justUpdated` (ou similar) voltar para o estado `updated` após alguns segundos para não poluir a UI indefinidamente.
- Seguir estritamente o desenvolvimento orientado a testes (TDD), alcançando 100% de cobertura nos testes unitários relevantes.

**Non-Goals:**
- Alterar a lógica de cache ou a forma como o `SyncNetwork` e o `SyncStorage` lidam com requisições 304.
- Alterar os visuais do aplicativo além da badge de sincronização existente.

## Decisions

1. **Adicionar `SyncStatus.noNewUpdates`**: Adicionar um novo valor ao enum `SyncStatus` (ex: `noNewUpdates` ou `alreadyUpdated`) que representará o estado em que a sincronização ocorreu com sucesso, mas nenhum dado novo foi baixado.
   - *Rationale*: Reutilizar a variável de status existente, mantendo a simplicidade da arquitetura, mas com granularidade maior de sucesso.

2. **Atualização no `SyncService`**: Quando o `SyncNetwork` retornar que a sincronização resultou em 304 (o que já é tratado pelo tipo de retorno `IndiceUnchanged` no `_SyncUpdates` ou retorno direto de `SyncNetwork`), o `SyncService` deve setar `syncStatus.value` para `SyncStatus.noNewUpdates` em vez de `SyncStatus.justUpdated`.
   - *Alternativas consideradas*: Poderíamos passar um booleano (ex: `wasModified`) mantendo o mesmo status de `justUpdated`, mas isso exigiria adicionar mais campos ao modelo e aumentaria a complexidade para todos os widgets observadores. Aumentar os valores possíveis de `SyncStatus` é mais semântico.

3. **Atualização na UI (`home_functions.dart` ou equivalente)**: Adicionar um `case SyncStatus.noNewUpdates` na construção do widget que mostra a badge, retornando o texto "Já atualizado" com uma cor mais neutra (como verde escuro ou azul suave) e um ícone adequado (como `Icons.check_circle_outline`). O timer que retorna a UI para o estado normal (após 4 segundos) deve também limpar esse novo estado.

## Risks / Trade-offs

- **[Risco] Falha no Reset Temporário do Status** → Como o estado `justUpdated` é resetado de volta para `updated` (ou `offline` / `outdated`) usando timers em partes específicas do código (como em testes ou em callbacks da UI), precisaremos garantir que todos esses timers sejam atualizados para resetar também o novo `SyncStatus.noNewUpdates`. 
   - *Mitigação*: Auditar todos os locais onde o timer temporário para `justUpdated` é agendado (por exemplo, dentro do `SyncService.setUpdatedStatus()` que usa `Future.delayed`).

## Migration Plan

- Modificar o enum `SyncStatus`.
- Atualizar a função `setUpdatedStatus()` no `SyncService` para aceitar um argumento de se houve modificação ou se foi 304.
- Atualizar a UI em `home_functions.dart`.
- Como TDD será usado, o desenvolvimento começará pela escrita/atualização de testes em `sync_service_test.dart` e `sync_status_timer_test.dart`, e possivelmente `home_functions_test.dart` antes de implementar o código funcional, garantindo 100% de cobertura.
