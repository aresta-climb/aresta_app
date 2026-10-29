# Proposal

## Why

Quando o usuário sai do aplicativo utilizando o botão ou gesto de "Voltar" a partir da raiz da tela inicial (`HomeNode`), o sistema atualmente invoca `SystemNavigator.pop()`, que executa `Activity.finish()` no Android e destrói a `MainActivity` e a `FlutterEngine` mantendo o processo Linux vivo em segundo plano. Ao reabrir o aplicativo em seguida, essa destruição força um *Cold Start* completo (e, em sessões de depuração/perfil, congela a nova `FlutterEngine` na splash nativa aguardando um debugger desconectado). Adicionalmente, o fluxo de *Cold Start* possui chamadas assíncronas pré-`runApp` e resolução inicial de *Deep Links* (`resolverDestinoInicialColdStart`) sem limites de tempo (*timeouts*) nem tratamento de falha garantido (`catchError`/`whenComplete`), podendo reter o usuário indefinidamente na splash screen caso um plugin nativo ou requisição de rede em conexão instável demore a responder.

## What Changes

- **Preservação da `MainActivity` e `FlutterEngine` ao sair pelo Voltar na raiz (`moveTaskToBack`)**: Substituir o encerramento destrutivo da atividade na raiz da `HomeNode` pelo envio da tarefa para segundo plano no Android (`moveTaskToBack(true)` via `MethodChannel` nativo, com fallback seguro para `SystemNavigator.pop()`), preservando a `FlutterEngine` aquecida em memória para retomada instantânea (*Warm/Hot Start*).
- **Garantia de saída da `TelaSplashInicial` com timeout e fallback para a Home**: Blindar `resolverDestinoInicialColdStart` e o listener de `resolucaoInicialColdStart` em `MyApp` com `timeout` e tratamento de erro (`catchError`), garantindo que `_aguardandoColdStart` sempre transicione para `false` e abra a `HomeNode` caso o processamento inicial exceda o tempo limite ou lance exceção — mantendo 100% intacto o bloqueio da `DatabaseMigrationScreen` quando `needsMigration == true` e da `TermsOfUsePage`.
- **Timeouts defensivos nas etapas assíncronas pré-`runApp`**: Adicionar limites de tempo seguros às inicializações de plugins nativos antes do `runApp()` (`initFirebase`, `GerenciadorNotificacaoDownload.inicializar` e `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano`) para impedir que travamentos de I/O ou IPC nativo bloqueiem a transição da splash nativa do sistema operacional para o Flutter.

## Capabilities

### New Capabilities

### Modified Capabilities
- `offline-first-initialization`: Adiciona garantias de tempo limite (*timeout*) e fallback seguro para a `HomeNode` na resolução de *Cold Start* da `TelaSplashInicial` e nas tarefas assíncronas pré-`runApp`, preservando integralmente o bloqueio de migração estrutural (`DatabaseMigrationScreen`).
- `navigation`: Altera o comportamento do retorno do sistema operacional na raiz da árvore de navegação (`HomeNode`) para enviar a tarefa para segundo plano (`moveTaskToBack`) sem destruir a atividade principal nem a `FlutterEngine`.

## Impact

- **Android Nativo**: `frontend/android/app/src/main/kotlin/com/example/frontend/MainActivity.kt` (registro de canal nativo enxuto para `moveTaskToBack(true)`).
- **Navegação**: `frontend/lib/navigation/wrapper_navegacao_arvore.dart` (uso de minimização não-destrutiva da tarefa ao pressionar Voltar na raiz da `HomeNode`).
- **Inicialização e Cold Start**: `frontend/lib/main.dart`, `frontend/lib/services/inicializacao_app.dart`, `frontend/lib/services/firebase/inicializar_firebase.dart` e `frontend/lib/application_managers/migracao/migracao_background_orchestrator.dart`.
- **Testes Automatizados**: Espelhamento 1:1 e cobertura comportamental de 100% nos testes correspondentes em `frontend/test/`.
