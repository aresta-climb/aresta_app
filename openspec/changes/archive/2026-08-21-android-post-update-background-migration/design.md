## Context

No ecossistema Android, atualizações automáticas via Google Play acontecem frequentemente em segundo plano enquanto o dispositivo está inativo, conectado ao carregador e ao Wi-Fi. Quando o Aresta lança uma nova versão com alterações estruturais no banco de dados (`kDataVersion`), a versão antiga dos dados é invalidada. Sem um hook pós-atualização, o usuário precisa passar pela `DatabaseMigrationScreen` no primeiro acesso. Com o hook, a migração ocorre de forma silenciosa e transparente antes que o usuário abra o aplicativo.

## Goals / Non-Goals

**Goals:**
- Configurar o broadcast nativo do Android `ACTION_MY_PACKAGE_REPLACED` para acordar o app pós-update da Play Store.
- Agendar e executar a sincronização do novo índice e download de croquis previamente salvos via `WorkManager` de forma modular e testável.
- Implementar a Estratégia A (Foreground Takeover) para cancelar com segurança a tarefa de background quando o usuário abrir o app, evitando concorrência e reaproveitando arquivos `.tmp` e dados já baixados.
- Garantir 100% de cobertura de testes em todos os arquivos modificados e criados, seguindo rigorosamente o `PRINCIPIOS.md`.

**Non-Goals:**
- Forçar hooks em segundo plano no iOS (a Apple não disponibiliza broadcasts pós-instalação e o `BGTaskScheduler` não é determinístico).
- Tentar travar a barra de progresso nativa da Google Play Store.

## Decisions

### 1. BroadcastReceiver Nativo + WorkManager OneOffTask
- **Decisão**: Criar um `BroadcastReceiver` nativo registrado no `AndroidManifest.xml` que escuta `android.intent.action.MY_PACKAGE_REPLACED`. Ao receber o evento, enfileira uma tarefa única no `WorkManager` (`tarefa_migracao_pos_atualizacao`) com restrição `NetworkType.CONNECTED`.
- **Alternativa considerada**: Iniciar um foreground service com notificação. *Rejeitada* por ser invasiva ao usuário e proibida pelo Android 12+ a partir de broadcasts em background.

### 2. Estratégia A: Foreground Takeover (Prioridade de Primeiro Plano)
- **Decisão**: A interface de usuário em primeiro plano é sempre a autoridade máxima. Ao inicializar em `main.dart`, o app chama `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano()`.
- **Rationale**: Elimina completamente condições de corrida (*race conditions*) e bloqueios entre múltiplos processos acessando os mesmos arquivos ou SharedPreferences. Se o WorkManager já tiver concluído parte dos downloads em `.tmp`, o `SyncService` no foreground retoma exatamente de onde o background parou.
- **Alternativa considerada**: Lockfiles inter-processo (`migration.lock`). *Rejeitada* devido ao risco de locks órfãos caso o SO mate o processo de background.

### 3. Componente Modular: `MigracaoBackgroundOrchestrator`
- **Decisão**: Criar a classe `MigracaoBackgroundOrchestrator` em `frontend/lib/application_managers/migracao/migracao_background_orchestrator.dart`, desacoplada da UI e com responsabilidade única de executar a sincronização headless e o cancelamento de tarefas.
- **Rationale**: Segue o Princípio II (Componentes Independentes / Feature-First) e o Princípio VI (Simplicidade e Anti-Abstração) do `PRINCIPIOS.md`, facilitando testes unitários isolados com 100% de cobertura.

## Risks / Trade-offs

- **[Risco] O usuário abre o app enquanto o WorkManager está no meio do download**
  → *Mitigação*: `main.dart` cancela a tarefa do WorkManager via Unique Name e assume o controle. O `SyncService` verifica os arquivos `.tmp` existentes e retoma o download sem perder o progresso.
- **[Risco] Dispositivo sem internet no momento da atualização da Play Store**
  → *Mitigação*: A tarefa do WorkManager é configurada com constraint de rede (`NetworkType.CONNECTED`), rodando apenas quando houver conectividade. Se não rodar até o usuário abrir o app, a `DatabaseMigrationScreen` assume com auto-retry reativo.

