## Why

Aproximadamente 80% dos usuários do Aresta utilizam a plataforma Android, onde atualizações da Google Play frequentemente ocorrem em segundo plano (especialmente durante a madrugada, com o aparelho conectado ao carregador e ao Wi-Fi). Atualmente, quando uma atualização do app envolve alteração estrutural no catálogo/dados (`kDataVersion`), o usuário pode se deparar com a tela de bloqueio e download forçado ao abrir o app. Ao disparar uma migração em segundo plano via `MY_PACKAGE_REPLACED` imediatamente após o término da atualização na Play Store, a maior parte dos usuários terá seus dados já migrados antes do primeiro acesso, eliminando atritos e telas de bloqueio.

## What Changes

- Adiciona um `BroadcastReceiver` nativo no Android para escutar `Intent.ACTION_MY_PACKAGE_REPLACED`.
- Enfileira uma tarefa de migração headless no `WorkManager` (`tarefa_migracao_pos_atualizacao`) com restrição de rede conectada.
- Implementa no `callbackDispatcher` a execução modular de `MigracaoBackgroundOrchestrator.executarMigracaoPosAtualizacao()` para sincronização silenciosa do novo índice e croquis locais.
- Implementa a **Estratégia A (Foreground Takeover)**: ao iniciar o aplicativo em primeiro plano (`main.dart`), cancela com segurança a tarefa de segundo plano (`cancelarMigracaoSegundoPlano`) e aproveita integralmente os arquivos `.tmp` e dados já baixados, eliminando concorrência destrutiva.
- Adiciona suíte de testes de widget e integração com 100% de cobertura seguindo o ciclo TDD (Vermelho-Verde-Refatorar).
- Todos os identificadores, classes, métodos e docstrings seguem estritamente o padrão em português brasileiro (`PRINCIPIOS.md`).

## Capabilities

### Modified Capabilities
- `offline-first-initialization`: Adiciona requisitos normativos de migração em segundo plano pós-atualização de pacote no Android com resolução segura de concorrência via prioridade de primeiro plano (Foreground Takeover).

## Impact

- **Nativo Android**: `android/app/src/main/AndroidManifest.xml` com registro do `BroadcastReceiver` para `ACTION_MY_PACKAGE_REPLACED`.
- **Orquestrador Modular**: `frontend/lib/application_managers/migracao/migracao_background_orchestrator.dart`.
- **Inicialização do App**: `frontend/lib/main.dart` com cancelamento seguro via `Workmanager().cancelByUniqueName()`.
- **Testes (TDD & 100% Cobertura)**: `frontend/test/application_managers/migracao/migracao_background_orchestrator_test.dart` e `frontend/test/main_test.dart`.

