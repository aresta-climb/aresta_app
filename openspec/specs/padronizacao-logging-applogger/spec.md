# padronizacao-logging-applogger Specification

## Purpose
Padronizar todas as emissões de logs e capturas de erro no aplicativo através do serviço `AppLogger`, garantindo rastreamento obrigatório de pilha (`stackTrace`) para o Firebase Crashlytics e Sentry, emissão de breadcrumbs em produção e fiscalização por teste arquitetural automatizado que impede chamadas diretas a `print` e `debugPrint`.

## Requirements

### Requirement: Rastreamento Obrigatório de Pilha (StackTrace) no Registro de Erros
O `AppLogger` SHALL exigir obrigatoriamente um parâmetro de rastreamento de pilha (`required StackTrace stackTrace`) nos métodos de registro de falhas `logError`, `logCrash` e `logFalhaSyncOuDownload`, garantindo que nenhuma falha seja registrada no Firebase Crashlytics ou no Sentry sem as informações de rastreamento da linha e arquivo de origem.

#### Scenario: Registro de erro não-fatal com rastreamento de pilha obrigatório
- **WHEN** o método `AppLogger.instance.logError` for invocado com uma mensagem de contexto, um objeto de erro e o respectivo `stackTrace` obrigatório
- **THEN** o sistema DEVE repassar o erro e o `stackTrace` tanto ao Firebase Crashlytics quanto ao Sentry (`Sentry.captureException`) e, em modo debug, imprimir a pilha de execução formatada no console.

#### Scenario: Registro de falha crítica ou de sincronização com rastreamento de pilha
- **WHEN** `logCrash` ou `logFalhaSyncOuDownload` (para erro que não seja falha de conexão/timeout) for invocado com erro e `stackTrace` obrigatório
- **THEN** o sistema DEVE encaminhar o `stackTrace` intacto para a chamada subjacente do Crashlytics e do Sentry (marcando o nível como `SentryLevel.fatal` quando `fatal == true`).

### Requirement: Suporte a Mensagens Informativas e Breadcrumbs
O `AppLogger` SHALL fornecer os métodos `logInfo` e `logAviso` com nomes e parâmetros em português brasileiro para rastreamento de ciclo de vida e eventos operacionais. Em modo de desenvolvimento (`kDebugMode`), os métodos DEVEM imprimir mensagens formatadas no console. Em modo de produção/release, os métodos DEVEM registrar breadcrumbs de diagnóstico simultaneamente no Firebase Crashlytics (`FirebaseCrashlytics.instance.log`) e no Sentry (`Sentry.addBreadcrumb`) sem poluir a lista de erros não-fatais.

#### Scenario: Registro de log informativo em modo debug
- **WHEN** `AppLogger.instance.logInfo("Mensagem informativa")` for chamado em ambiente com debug ativado
- **THEN** o sistema DEVE emitir a mensagem formatada para o console local utilizando o prefixo informativo.

#### Scenario: Registro de breadcrumbs em modo release
- **WHEN** `AppLogger.instance.logInfo("Sincronização iniciada")` ou `AppLogger.instance.logAviso("Cache expirado")` for chamado em ambiente de produção (release)
- **THEN** o sistema DEVE registrar a mensagem no Firebase Crashlytics através de `FirebaseCrashlytics.instance.log` e adicionar um `Breadcrumb` correspondente no Sentry (`SentryLevel.info` para `logInfo` e `SentryLevel.warning` para `logAviso`).

### Requirement: Isolamento Arquitetural contra Chamadas Diretas a Print e DebugPrint
O repositório SHALL possuir um teste arquitetural automatizado na pasta `test/architecture/isolamento_logs_arquitetura_test.dart` que analisa recursivamente todos os arquivos Dart em `lib/` e falha se qualquer arquivo que não seja `lib/services/firebase/app_logger.dart` invocar diretamente `print(` ou `debugPrint(`.

#### Scenario: Execução da suíte de testes arquiteturais em conformidade
- **WHEN** o teste `flutter test test/architecture/isolamento_logs_arquitetura_test.dart` for executado e nenhum arquivo em `lib/` além de `app_logger.dart` contiver `print` ou `debugPrint`
- **THEN** o teste DEVE passar com sucesso.

#### Scenario: Violação arquitetural detectada por novo código
- **WHEN** um arquivo sob `lib/` que não seja `app_logger.dart` contiver uma instrução `debugPrint(...)` ou `print(...)`
- **THEN** o teste DEVE falhar indicando o caminho do arquivo, a linha exata da infração e a instrução para utilizar `AppLogger.instance`.

### Requirement: Propagação Completa de Exceções e StackTrace em Blocos de Captura
Todos os blocos de captura de exceções (`catch`) da aplicação sob `lib/` que realizam registro de falhas operacionais e de rede SHALL capturar explicitamente a exceção e o rastreamento de pilha `catch (e, stackTrace)` e encaminhá-los integralmente ao `AppLogger`.

#### Scenario: Tratamento de exceção em serviço de background ou sincronização
- **WHEN** uma exceção não esperada for interceptada em um bloco `catch` de um serviço
- **THEN** o bloco DEVE capturar o `stackTrace` do evento e invocar `AppLogger.instance.logError` passando o `error: e` e `stackTrace: stackTrace`.

### Requirement: Cobertura de Testes e Prática Estrita de TDD
Todas as alterações no serviço de log e no teste arquitetural SHALL seguir o ciclo Red-Green-Refactor, com testes criados antes da implementação e atingindo 100% de cobertura de código no `AppLogger` e `MockAppLogger`.

#### Scenario: Execução dos testes unitários do logger
- **WHEN** a suíte de testes do `AppLogger` for executada via `flutter test test/services/firebase/app_logger_test.dart`
- **THEN** todos os cenários de `logError`, `logCrash`, `logFalhaSyncOuDownload`, `logInfo` e `logAviso` DEVEM passar com 100% de cobertura.

### Requirement: Reconhecimento de Falhas de Rede Nativas de SDKs do Firebase
O método `AppLogger.isFalhaConexaoOuTimeout` SHALL reconhecer exceções e mensagens de erro originadas nos SDKs nativos do Firebase (`FirebaseException`, Firebase Installations, Firebase Remote Config e Firebase App Check) quando decorrentes de indisponibilidade de rede, falha ao obter token de instalação para busca ou falha de comunicação do cliente com o backend.

#### Scenario: Falha ao obter token do Firebase Installations durante fetch do Remote Config
- **WHEN** `AppLogger.isFalhaConexaoOuTimeout` for invocado com uma exceção contendo `[firebase_remote_config/internal] Firebase Installations failed to get installation auth token for fetch.`
- **THEN** o método DEVE retornar `true`.

#### Scenario: Falha de comunicação do cliente nativo do Firebase com o backend
- **WHEN** `AppLogger.isFalhaConexaoOuTimeout` for invocado com uma `FirebaseException` de código `unavailable` ou `network-request-failed`, ou mensagem contendo `the client had an error while calling the backend`, `unable to connect to the server` ou `fetch failed`
- **THEN** o método DEVE retornar `true`.

#### Scenario: Falha de rede ao obter token do App Check
- **WHEN** `AppCheckService.instance.getToken()` capturar uma exceção de rede ou indisponibilidade reconhecida por `AppLogger.isFalhaConexaoOuTimeout`
- **THEN** o serviço DEVE registrar a ocorrência via `AppLogger.instance.logAviso` (breadcrumb) em vez de `logError`, retornando `null` sem abrir issue não-fatal no Crashlytics.

### Requirement: Prevenção de Falsos Crashes Fatais por Omissão da Exceção de Rede Original
Os serviços e orquestradores de UI (`handlePicoSelection`, `SyncService.downloadCrag`, `ServicoDownloadSegundoPlano.executarDownload` e `ServicoCroquiOnline.recarregarCroquiOnline`) SHALL preservar a classificação de falhas de conectividade realizada pela camada de transporte inferior, sendo proibido invocar `AppLogger.instance.logFalhaSyncOuDownload` ou `AppLogger.instance.logCrash` sem o objeto de erro original (`error: null`) ou com exceções sintéticas genéricas quando uma operação retornar `null` ou `false` em decorrência de falha de rede já registrada.

#### Scenario: Falha de download de croqui por ausência de conexão no SyncService
- **WHEN** `SyncService.downloadCrag` falha após as tentativas porque o isolate de download encontrou `SocketException`, `ClientException` ou `TimeoutException` (já registrado via `tratarErroDownloadIsolate`)
- **THEN** o encerramento de `downloadCrag` DEVE registrar o resumo de falha via `AppLogger.instance.logAviso`
- **AND** NÃO DEVE invocar `logFalhaSyncOuDownload` sem o erro original, evitando o disparo de `logCrash(fatal: true)`.

#### Scenario: Falha de download em segundo plano por ausência de conexão
- **WHEN** `ServicoDownloadSegundoPlano.executarDownload` recebe `sucesso == false` de `syncService.downloadCrag`
- **THEN** o serviço DEVE registrar o encerramento sem sucesso via `AppLogger.instance.logAviso` e exibir a notificação de falha ao usuário
- **AND** NÃO DEVE invocar `logFalhaSyncOuDownload` sem objeto `error`, evitando duplicação de crash fatal no Crashlytics.
