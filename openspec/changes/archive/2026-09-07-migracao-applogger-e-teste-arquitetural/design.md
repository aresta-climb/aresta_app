## Context

O Aresta Climb adota o [PRINCIPIOS.md](../../../PRINCIPIOS.md) como diretriz basilar inegociável de engenharia (Tudo em Português, TDD Obrigatório, 100% Test Coverage, Simplicidade e Documentação Contínua). 

Atualmente, o `AppLogger` atua como fachada para envio de erros ao Firebase Crashlytics e impressão em console durante o desenvolvimento local. Entretanto, a aplicação possui três fragilidades que violam os padrões de qualidade do projeto:
1. **Omissão de Rastreamento de Pilha**: O parâmetro `stackTrace` era opcional em `AppLogger.instance.logError`. Como consequência, 37 blocos de captura de erro invocavam o logger sem `stackTrace`, fazendo com que o Firebase Crashlytics agrupasse as ocorrências na linha interna de `app_logger.dart:118` (`recordError`), ocultando o arquivo e a linha onde a exceção realmente ocorreu.
2. **Erros Não Reportados em Produção**: 37 blocos `catch` utilizavam `debugPrint` ou `print`. Em builds de release para os usuários finais, essas saídas são descartadas, fazendo com que falhas reais de rede, banco e sincronização sejam perdidas.
3. **Ausência de Logs Informativos Padronizados**: O `AppLogger` cobria apenas erros. Eventos de ciclo de vida (Live Reload, migrações em background, início de sincronização) recorriam a chamadas diretas a `debugPrint`, impedindo o uso de breadcrumbs no Crashlytics.

## Goals / Non-Goals

**Goals:**
- Seguir estritamente o **TDD (Test-Driven Development)**: escrever os testes antes de qualquer alteração de código produtivo (ciclo Red-Green-Refactor).
- Exigir 100% de cobertura de testes unitários no `AppLogger` e suas variantes mockadas.
- Tornar o parâmetro `stackTrace` estritamente obrigatório (`required StackTrace stackTrace`) em `AppLogger.instance.logError`, `logCrash` e `logFalhaSyncOuDownload`.
- Adicionar os métodos `logInfo(String mensagem)` e `logAviso(String mensagem, {dynamic erro, StackTrace? rastreamentoPilha})` ao `AppLogger`, com saída em console no modo debug e breadcrumbs via `FirebaseCrashlytics.instance.log` em release.
- Atualizar `MockAppLogger` e todos os testes unitários de `AppLogger`.
- Escrever o teste arquitetural `test/architecture/isolamento_logs_arquitetura_test.dart` que fiscaliza e bloqueia o uso de `print` ou `debugPrint` em `lib/` (exceto dentro do próprio `app_logger.dart`).
- Migrar 100% das ocorrências de `debugPrint` e `print` em `lib/` para o `AppLogger`.
- Ajustar os blocos `catch` da aplicação para capturar `(e, stackTrace)` e encaminhar a pilha de execução completa.
- Habilitar `avoid_print: true` em `analysis_options.yaml`.
- Documentar exaustivamente todos os métodos com comentários de documentação `///` em português brasileiro e atualizar os arquivos `README.md` pertinentes.

**Non-Goals:**
- Proibir `print` dentro da suíte de testes (`test/`), de scripts utilitários isolados em Python (`lib/aresta_api/build.py`) ou ferramentas de linha de comando.
- Modificar o fluxo funcional de regras de negócio ou telas do aplicativo além da substituição das chamadas de log e captura correta de exceções.

## Decisions

### Decisão 1: Conformidade com o TDD (Princípio IV)
- **Abordagem**: O ciclo Red-Green-Refactor será executado em duas frentes:
  1. *Frente Arquitetural*: O teste `isolamento_logs_arquitetura_test.dart` será escrito primeiro. Ao rodar inicialmente, ele falhará (RED) devido às mais de 100 ocorrências existentes de `debugPrint`/`print`. Ele passará (GREEN) apenas quando a última ocorrência for migrada.
  2. *Frente de Unidade*: Os testes de unidade em `test/services/firebase/app_logger_test.dart` serão atualizados primeiro para exigir o `required StackTrace stackTrace` e validar `logInfo`/`logAviso`. Falharão na compilação/execução (RED), sendo corrigidos pela implementação do `AppLogger` e `MockAppLogger` (GREEN), mantendo 100% de cobertura (Princípio III).

### Decisão 2: Nomenclatura e Documentação em Português (Princípios I e VII)
- **Abordagem**:
  - Parâmetros e novos métodos seguem português brasileiro: `logInfo(String mensagem)`, `logAviso(String mensagem, {dynamic erro, StackTrace? rastreamentoPilha})`.
  - Os parâmetros de `logError` serão compatibilizados para exigir `required StackTrace stackTrace`, mantendo o nome legado `logError` já disseminado, com parâmetros documentados em português.
  - O arquivo de teste arquitetural é nomeado em português: `test/architecture/isolamento_logs_arquitetura_test.dart`.
  - Todas as funções e classes recebem comentários `///` no formato DartDoc explicando o motivo (intenção) e funcionamento.
  - Atualização dos arquivos `lib/services/firebase/README.md` e `test/architecture/README.md`.

### Decisão 3: `required StackTrace stackTrace` nas Assinaturas de Erro
- **Escolha**: Parâmetro obrigatório em tempo de compilação em `logError`, `logCrash` e `logFalhaSyncOuDownload`.
- **Por que não usar `StackTrace.current` automático?**: No modelo assíncrono do Dart (`async`/`await`), chamar `StackTrace.current` dentro de um método utilitário captura apenas os quadros do ponto onde a linha de log foi chamada, perdendo o histórico de execução assíncrona da exceção original. A sintaxe explícita `catch (e, stackTrace)` preserva a rastreabilidade original exata no Crashlytics.

### Decisão 4: Breadcrumbs de Diagnóstico no Crashlytics em Release
- **Escolha**: Em builds de release (`!kDebugMode`), `logInfo` e `logAviso` invocam `FirebaseCrashlytics.instance.log(...)`.
- **Benefício**: Não polui o painel do Firebase com erros falsos ou ruído de métricas, mas quando qualquer crash ou erro subsequente ocorrer, o Crashlytics anexa o histórico das últimas mensagens registradas pelo app antes da falha, facilitando a reprodução do problema na montanha ou em campo.

### Decisão 5: Simplicidade e Anti-Abstração (Princípio VI)
- **Escolha**: Manter o `AppLogger` como uma classe direta, singleton simples acessado via `AppLogger.instance`, sem criar camadas intermediárias desnecessárias ou proxies complexos. *"Melhor um pouco de duplicação do que a abstração errada."*

## Risks / Trade-offs

- **[Risco] Quebra de compilação transitória ao tornar `stackTrace` obrigatório** → *Mitigação*: Implementar primeiro o contrato nos testes e no logger, seguido por migração estruturada por módulos (`services`, `background`, `pages`, `widgets`), garantindo que o compilador Dart e o `flutter analyze` guiem todas as correções sem deixar nada para trás.
- **[Risco] Falsos positivos no teste arquitetural com comentários ou strings que mencionam "print"** → *Mitigação*: O teste descartará comentários (`//`) e utilizará expressões regulares com delimitação de palavras (`\bdebugPrint\s*\(` e `(?<![a-zA-Z0-9_])print\s*\(`).
- **[Risco] Execução em Isolates de background (`sync_isolate.dart`)** → *Mitigação*: Isolates secundários de processamento não inicializam plugins de plataforma nativa. As falhas continuam sendo serializadas com `stackTrace` dentro do objeto `DownloadIsolateResult.rastreamentoPilha` e repassadas ao `AppLogger` no Isolate principal através de `tratarErroDownloadIsolate`.
