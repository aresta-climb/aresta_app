## Why

Atualmente, o aplicativo possui mais de 100 ocorrências de `debugPrint` e `print` espalhadas pelo código de produção, além de 37 blocos de `catch` que utilizam `debugPrint`, fazendo com que erros reais em produção sejam 100% perdidos sem chegar ao Firebase Crashlytics. Adicionalmente, 37 chamadas existentes a `AppLogger.instance.logError` omitem o parâmetro `stackTrace`, fazendo com que o Firebase Crashlytics agrupe todos os relatórios na mesma linha de `app_logger.dart:118` e degrade severamente o diagnóstico de falhas em campo.

Para erradicar permanentemente essas falhas silenciosas e a falta de contexto de depuração, precisamos tornar o `stackTrace` estritamente obrigatório em erros do `AppLogger`, expandir o logger com suporte a logs informativos e de aviso (`logInfo` / `logAviso`) com breadcrumbs em produção, migrar todas as impressões diretas e introduzir um teste arquitetural automatizado que impeça o uso de `print` ou `debugPrint` em `lib/`.

Toda a alteração seguirá rigorosamente as diretrizes de [PRINCIPIOS.md](../../../PRINCIPIOS.md): desenvolvimento guiado por testes (TDD obrigatório com ciclo Red-Green-Refactor), 100% de cobertura, nomenclatura e documentação em português brasileiro, docstrings completas em `///` e atualização contínua dos `README.md`.

## What Changes

- **BREAKING**: Torna o parâmetro `stackTrace` obrigatório (`required StackTrace stackTrace`) em `AppLogger.instance.logError`, `logCrash` e `logFalhaSyncOuDownload`.
- Adiciona os métodos `logInfo(String mensagem)` e `logAviso(String mensagem, {dynamic erro, StackTrace? rastreamentoPilha})` ao `AppLogger`. Em modo debug, imprimem no console local formatados; em modo release, registram *breadcrumbs* via `FirebaseCrashlytics.instance.log(mensagem)`.
- Atualiza `MockAppLogger` e os testes de unidade de `AppLogger` para refletir as novas assinaturas e comportamentos com 100% de cobertura.
- Adiciona teste arquitetural em `test/architecture/isolamento_logs_arquitetura_test.dart` (escrito em TDD no estágio inicial Red) que falha na compilação/teste se qualquer arquivo sob `lib/` (exceto `app_logger.dart`) contiver chamadas diretas a `print(` ou `debugPrint(`.
- Migra todas as ocorrências de `debugPrint` e `print` em `lib/` (111 no total) para `AppLogger.instance.logInfo`, `logAviso` ou `AppLogger.instance.logError`.
- Converte todos os blocos de captura de exceções (`catch`) relevantes em `lib/` para capturar `(e, stackTrace)` e encaminhar o rastreamento completo ao `AppLogger`.
- Elimina pontos cegos críticos onde falhas eram engolidas silenciosamente (como em `pages/database_migration_screen.dart`).
- Ativa a regra de linter `avoid_print: true` no `analysis_options.yaml`.
- Atualiza os arquivos `README.md` pertinentes (`lib/services/firebase/README.md` e `test/architecture/README.md`) e documenta todos os métodos com docstrings completas em português.

## Capabilities

### New Capabilities
- `padronizacao-logging-applogger`: Centralização estrita do logging de aplicação via AppLogger em conformidade com PRINCIPIOS.md, exigindo rastreamento de pilha (StackTrace) em erros, suporte a breadcrumbs no Crashlytics, TDD e garantia arquitetural contínua contra uso de print/debugPrint.

### Modified Capabilities
<!-- Nenhuma especificação de regra de negócio existente teve seus requisitos alterados. -->

## Impact

- **Código Afetado**: `lib/services/firebase/app_logger.dart`, `test/mocks/mock_app_logger.dart`, `test/services/firebase/app_logger_test.dart`, todas as classes de serviços e páginas que usavam `debugPrint`/`print` ou `catch (e)`.
- **APIs**: Contrato de `AppLogger` alterado para exigir `StackTrace`.
- **Qualidade, CI e TDD**: `flutter test test/architecture/` e `flutter analyze` passam a fiscalizar ativamente o uso de logs diretos.
- **Produção**: Aumento drástico na visibilidade de crashes e erros não-fatais no Firebase Crashlytics com rastreamento exato da linha de origem.
- **Documentação**: `README.md` das pastas afetadas e docstrings completas em conformidade com o Princípio VII.
