## 1. Domain / Model

- [ ] 1.1 Adicionar `noNewUpdates` (ou similar) ao enum `SyncStatus` em `frontend/lib/services/http/sync_service.dart`.

## 2. Lógica de Sincronização

- [ ] 2.1 Em `SyncService.syncIndex()`, onde é tratado o `IndiceUnchanged()` (retorno 304), definir `syncStatus.value = SyncStatus.noNewUpdates` no lugar da chamada ou internamente em `setUpdatedStatus()`/diretamente.
- [ ] 2.2 Garantir que o `SyncStatus.noNewUpdates` também seja resetado de volta para `updated` (ou `offline`/`outdated`) após alguns segundos, similar a como ocorre com `justUpdated`. (Verificar e possivelmente atualizar `setUpdatedStatus()`).

## 3. UI (Feedback Visual)

- [ ] 3.1 Atualizar o switch em `home_functions.dart` (ou onde a badge é renderizada) para tratar o `case SyncStatus.noNewUpdates`.
- [ ] 3.2 Definir no `case` o texto "Já está atualizado" (ou "Sem atualizações"), com um ícone apropriado e cor suave (como verde ou azul neutro).

## 4. Testes

- [ ] 4.1 Atualizar ou adicionar testes em `sync_status_timer_test.dart` para validar a transição de status para `noNewUpdates` e de volta para `updated`.
- [ ] 4.2 Ajustar os testes em `sync_service_test.dart` que simulam uma resposta `304` e esperam o status `justUpdated`, para agora esperar `noNewUpdates`.
