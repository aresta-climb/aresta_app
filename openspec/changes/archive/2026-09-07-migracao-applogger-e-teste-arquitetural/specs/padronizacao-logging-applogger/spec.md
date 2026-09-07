## ADDED Requirements

### Requirement: Rastreamento Obrigatório de Pilha (StackTrace) no Registro de Erros
O `AppLogger` SHALL exigir obrigatoriamente um parâmetro de rastreamento de pilha (`required StackTrace stackTrace`) nos métodos de registro de falhas `logError`, `logCrash` e `logFalhaSyncOuDownload`, garantindo que nenhuma falha seja registrada no Firebase Crashlytics sem as informações de rastreamento da linha e arquivo de origem.

#### Scenario: Registro de erro não-fatal com rastreamento de pilha obrigatório
- **WHEN** o método `AppLogger.instance.logError` for invocado com uma mensagem de contexto, um objeto de erro e o respectivo `stackTrace` obrigatório
- **THEN** o sistema DEVE repassar o `stackTrace` ao Firebase Crashlytics e, em modo debug, imprimir a pilha de execução formatada no console.

#### Scenario: Registro de falha crítica ou de sincronização com rastreamento de pilha
- **WHEN** `logCrash` ou `logFalhaSyncOuDownload` for invocado com erro e `stackTrace` obrigatório
- **THEN** o sistema DEVE encaminhar o `stackTrace` intacto para a chamada subjacente do Crashlytics.

### Requirement: Suporte a Mensagens Informativas e Breadcrumbs
O `AppLogger` SHALL fornecer os métodos `logInfo` e `logAviso` com nomes e parâmetros em português brasileiro para rastreamento de ciclo de vida e eventos operacionais. Em modo de desenvolvimento (`kDebugMode`), os métodos DEVEM imprimir mensagens formatadas no console. Em modo de produção/release, os métodos DEVEM registrar breadcrumbs de diagnóstico via `FirebaseCrashlytics.instance.log` sem poluir a lista de erros não-fatais.

#### Scenario: Registro de log informativo em modo debug
- **WHEN** `AppLogger.instance.logInfo("Mensagem informativa")` for chamado em ambiente com debug ativado
- **THEN** o sistema DEVE emitir a mensagem formatada para o console local utilizando o prefixo informativo.

#### Scenario: Registro de breadcrumbs em modo release
- **WHEN** `AppLogger.instance.logInfo("Sincronização iniciada")` for chamado em ambiente de produção (release)
- **THEN** o sistema DEVE registrar a mensagem no Firebase Crashlytics através de `FirebaseCrashlytics.instance.log` para servir de histórico de diagnóstico em eventuais falhas futuras.

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
