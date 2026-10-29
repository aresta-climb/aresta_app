# Design

## Context

Conforme detalhado em `proposal.md`, a investigação de *logs* reais do dispositivo (`adb logcat`) revelou que sair do aplicativo pelo botão/gesto "Voltar" na raiz da `HomeNode` aciona `SystemNavigator.pop()`, o que destrói a `MainActivity` e a `FlutterEngine` (`Activity.finish()`) mantendo o processo Linux vivo em memória. Ao reabrir o aplicativo segundos depois, o Android instancia uma nova `MainActivity` e `FlutterEngine` no mesmo processo — o que força um *Cold Start* desnecessário em produção e congela a Dart VM na splash nativa em sessões de depuração. Além disso, o caminho de *Cold Start* carece de limites de tempo (*timeouts*) e tratamento de erro garantido na transição da `TelaSplashInicial` e nos canais nativos pré-`runApp()`.

Todas as decisões abaixo seguem estritamente os 8 princípios do `AGENTS.md` (código 100% em português, modularidade, TDD com 100% de cobertura comportamental, espelhamento 1:1 de testes e ausência de mocks internos).

## Goals / Non-Goals

**Goals:**
- Preservar a `MainActivity` e a `FlutterEngine` em memória quando o usuário sair do aplicativo pelo botão/gesto "Voltar" na raiz da `HomeNode`, movendo a tarefa para segundo plano (`moveTaskToBack(true)`).
- Garantir determinismo absoluto na saída da `TelaSplashInicial`, assegurando que `_aguardandoColdStart` sempre mude para `false` mesmo sob exceções ou conexões HTTP penduradas durante a resolução de *Deep Links* no *Cold Start*.
- Proteger o bootstrap pré-`runApp()` com *timeouts* defensivos em chamadas de plugins nativos (`Workmanager`, `Firebase`, `FlutterLocalNotifications`).
- Manter 100% intacto o bloqueio da `DatabaseMigrationScreen` (`needsMigration == true`) e da `TermsOfUsePage`.

**Non-Goals:**
- Alterar a lógica de verificação ou execução da migração estrutural de versão de dados (`kDataVersion` em `DatabaseMigrationScreen`).
- Alterar o comportamento de navegação interna entre páginas ou abas secundárias.

## Decisions

### 1. Canal Nativo de Ciclo de Vida para `moveTaskToBack(true)` na Raiz da Home
- **Decisão**: Registrar em `MainActivity.kt` (`configureFlutterEngine`) um `MethodChannel` leve (`"app.escalada.croquis/ciclo_vida"`) respondendo ao método `"minimizarTarefa"` com `moveTaskToBack(true)`. No Flutter, encapsular essa chamada na função utilitária `minimizarAplicativo()` (em `funcoes_navegacao.dart` ou `wrapper_navegacao_arvore.dart`), invocada pelo `PopScope` do `TreeNavigationWrapper` quando já estiver na raiz da `HomeNode`. Se o canal lançar `MissingPluginException`, `PlatformException` ou retornar `false`, executa fallback para `SystemNavigator.pop()`.
- **Racional**: Diferente de `SystemNavigator.pop()` (que chama `Activity.finish()` e destrói a `FlutterEngine`), `moveTaskToBack(true)` replica exatamente o comportamento do botão Home do Android: a atividade passa por `onPause()` $\rightarrow$ `onStop()`, preserva a árvore de widgets e a `FlutterEngine` na RAM e permite retomada instantânea (*Warm/Hot Start*).
- **Alternativas consideradas**:
  - *Habilitar `canPop: true` dinamicamente no `PopScope`*: Rejeitado porque a decisão de voltar depende de estados avaliados dentro de `onPopInvokedWithResult` (como `SubmitFeedbackUseCase.isFeedbackOpen`, `treeController.goBack()` e troca de aba secundária para a aba 0).

### 2. Timeout e Fallback Seguro em `resolverDestinoInicialColdStart` e `_MyAppState`
- **Decisão**:
  1. Em `resolverDestinoInicialColdStart` (`inicializacao_app.dart`), adicionar parâmetro opcional `Duration timeoutResolucao = const Duration(seconds: 8)` e envolver a resolução do link inicial em bloco `try / catch` com `.timeout(timeoutResolucao)`. Caso ocorra `TimeoutException` ou qualquer erro inesperado, registrar aviso via `AppLogger.instance.logWarning` e retornar `ResultadoResolucaoColdStart(treeController: controller)` apontando para a `HomeNode`.
  2. Em `_MyAppState.initState` (`main.dart`), adicionar `.catchError(...)` na `Future` `widget.resolucaoInicialColdStart!` para garantir que, mesmo que uma `Future` customizada rejeite com erro, `_aguardandoColdStart` seja definido como `false` via `setState` e o aplicativo renderize a `HomeNode`.
- **Invariância da `DatabaseMigrationScreen` (`tela_migracao_banco.dart`)**:
  - A verificação `needsMigration = await setupAppServices(datasetRepo, syncService)` é puramente local (`SharedPreferences` + existência de `indice.binarypb`) e ocorre **antes** de `resolverDestinoInicialColdStart`.
  - Quando `needsMigration == true`, `resolucaoColdStart` recebe `null` e o `MaterialApp.builder` substitui a árvore inteira pela `DatabaseMigrationScreen` enquanto `_needsMigration && _hasAcceptedTerms` for verdadeiro. Portanto, o *timeout* da `TelaSplashInicial` jamais afeta, interrompe ou pula a tela de migração de banco de dados.

### 3. Timeouts Defensivos nas Operações Nativa de Pré-Boot
- **Decisão**:
  - Em `MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano`, adicionar `.timeout(timeoutCancelamento)` (padrão `Duration(seconds: 2)`) sobre `wm.cancelByUniqueName(...)` dentro do `try/catch` já existente.
  - Em `inicializacao_app.dart`, criar um helper ou aplicar `.timeout()` defensivo nas inicializações paralelas de plugins externos antes do `runApp()` para que falhas de IPC nativo degradem silenciosamente com log de aviso sem congelar a splash nativa do Android.

## Risks / Trade-offs

- **[Risco] Deep Link em Cold Start sob internet 2G extremamente lenta (> 8s) cair para a Home** $\rightarrow$ **Mitigação**: 8 segundos é um limite generoso para resolução inicial em *Cold Start* (muito melhor do que congelar o app indefinidamente na splash screen sem resposta visual). Além disso, ao cair para a Home com uma mensagem de aviso amigável (`mensagemAvisoInicial`), o usuário tem controle imediato do aplicativo.
- **[Risco] Testes de widget existentes que verificam `SystemChannels.platform` (`SystemNavigator.pop`)** $\rightarrow$ **Mitigação**: Quando o canal `"app.escalada.croquis/ciclo_vida"` não possui handler registrado (padrão em testes que não mockam esse canal), o fallback chama automaticamente `SystemNavigator.pop()`, mantendo compatibilidade retroativa total e permitindo testar ambos os cenários.
