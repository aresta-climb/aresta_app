# Design

## Context

Veja `proposal.md` para motivação e descrição do problema.
O sistema possui uma instância de `ServicoCroquiOnline` mantida no `DatasetRepository` (`datasetRepo.servicoCroquiOnline`). Essa instância encapsula o cliente HTTP (`_client`) e os timers de polling para croquis abertos online.
Ao refatorar a `PicoDetailsPage` para o modelo dumb UI com `PicoViewModel`, a injeção de dependência forneceu `datasetRepo.servicoCroquiOnline` ao `PicoViewModel`. Contudo, ao desmontar a página, `PicoViewModel.dispose()` acionou `_servicoCroquiOnline.dispose()`, que executa `_client.close()`.
Subsequentemente, novas requisições HTTP falham com `ClientException: Cannot send request after connection is closed`. O fallback em `funcoes_home.dart` tenta criar um novo `ServicoCroquiOnline`, mas utiliza um `caminhoRelativo` sem host base e sem tratamento unificado, resultando em erro silencioso para a telemetria e exibição da SnackBar "Erro ao abrir o guia. Verifique sua conexão.".

## Goals / Non-Goals

**Goals:**
- Garantir que o `PicoViewModel` não encerre o `ServicoCroquiOnline` nem feche seu cliente HTTP ao ser descartado.
- Garantir que múltiplos croquis online possam ser abertos, fechados e reabertos consecutivamente sem falhas de conexão fechada.
- Sanear a recuperação sob demanda de croquis em `funcoes_home.dart`, centralizando a resolução no `DatasetRepository.getCroqui(id)` e garantindo URLs absolutas corretas.
- Assegurar observabilidade total no Firebase Crashlytics: emitir `AppLogger.instance.logFalhaSyncOuDownload` (ou `logError`) sempre que uma abertura de guia falhar ou cair em exceções não tratadas na interface ou no serviço de croqui online.

**Non-Goals:**
- Não alterar a arquitetura do `GerenciadorSessaoOnline` ou o formato binário do protobuf `Croqui`.
- Não modificar o fluxo de croquis offline (já salvos em disco), que operam de forma isolada e sem dependência de rede.

## Decisions

### 1. Desacoplamento do Ciclo de Vida em `PicoViewModel.dispose()`
- **Decisão:** Remover a invocação `_servicoCroquiOnline.dispose()` de `PicoViewModel.dispose()`. Manter estritamente o cancelamento do polling do pico específico: `_servicoCroquiOnline.cancelarPolling(cragId)`.
- **Alternativa Rejeitada:** Criar uma nova instância de `http.Client()` para cada `PicoViewModel`. Isso desperdiçaria conexões persistentes, degradaria performance de rede e não resolveria a destruição da instância mantida no `DatasetRepository`.

### 2. Centralização da Resolução no `DatasetRepository.getCroqui(id)`
- **Decisão:** No `DatasetRepository.getCroqui(id)`, caso o resumo não seja encontrado no `indiceData.value`, consultar também como salvaguarda o `activeDataset.value?.metadadosDisponiveis` para obter `caminhoRelativo` e `checksumSha256Croqui`. Sempre compor a URL absoluta com `editorDeCroqui.activeBaseUrl`.
- **Saneamento de `funcoes_home.dart`:** Remover a lógica espaguete de fallback manual com URI relativa e nova instância não configurada de `ServicoCroquiOnline`. Delegar a obtenção estritamente a `datasetRepo.getCroqui(id)`.

### 3. Observabilidade Obrigatória de Falhas no Firebase Crashlytics
- **Decisão:** Em `funcoes_home.dart.handlePicoSelection`, se `croqui == null || croqui.picos.isEmpty`, invocar:
  ```dart
  AppLogger.instance.logFalhaSyncOuDownload(
    'Falha ao abrir guia do pico: $id (origem: $source)',
    error: Exception('Croqui nulo ou sem picos após consulta ao repositório'),
    stackTrace: StackTrace.current,
  );
  ```
  Isso garante que, mesmo quando a UI amigavelmente exibe a SnackBar para o usuário, o evento seja registrado no Crashlytics com o stack trace do ponto de chamada da UI e o ID do pico.
- **No `ServicoCroquiOnline.carregarCroquiRemoto`:** Usar `AppLogger.instance.logFalhaSyncOuDownload` na captura de exceção e no status HTTP != 200, garantindo a classificação correta de erros transitórios vs anomalias de cliente fechado.

## Risks / Trade-offs

- **[Risco] Vazamento de Timers de Polling se múltiplos picos forem abertos:**
  - *Mitigação:* `PicoViewModel.dispose()` já chama `_servicoCroquiOnline.cancelarPolling(cragId)`, e `ServicoCroquiOnline.iniciarPollingEtag` cancela deterministamente qualquer timer prévio do mesmo `cragId`.
- **[Risco] Ruído excessivo no Crashlytics se o usuário estiver offline:**
  - *Mitigação:* `logFalhaSyncOuDownload` utiliza `AppLogger.isFalhaConexaoOuTimeout`. Se a falha for desconexão de rede (ex: `SocketException`, modo avião, timeout), ela é registrada como `logAviso` (breadcrumb contextual) sem poluir o painel de issues, mas se for cliente fechado, 404, 500 ou parsing com erro, é registrada como crash/erro rastreável.
