# Proposal

## Why

Atualmente, ao navegar e sair da tela de um croqui online (`PicoDetailsPage`), o método `PicoViewModel.dispose()` encerra indevidamente o cliente HTTP compartilhado (`_servicoCroquiOnline.dispose()` -> `_client.close()`). Quando o usuário tenta abrir subsequentemente qualquer outro croqui online, as requisições falham com `ClientException: Cannot send request after connection is closed` e a interface exibe a mensagem "Erro ao abrir o guia. Verifique sua conexão.". 

Além disso, falhas ao tentar abrir guias na interface e tentativas de fallback em `funcoes_home.dart` são absorvidas silenciosamente sem emissão de logs estruturados para o Firebase Crashlytics (`AppLogger`), impedindo a observabilidade e a abertura de tickets no painel de monitoramento do time.

## What Changes

- **Ciclo de vida do `PicoViewModel`**: Elimina a chamada destrutiva a `_servicoCroquiOnline.dispose()` no descarte do ViewModel da tela do pico, mantendo estritamente o cancelamento do polling do pico específico (`cancelarPolling(cragId)`).
- **Saneamento do fluxo de carregamento sob demanda em `funcoes_home.dart`**: Remove ou corrige o fallback redundante com URI relativa sem host, consolidando `DatasetRepository.getCroqui` como autoridade única de recuperação de croquis (RAM -> Offline permanente -> Cache volátil -> CDN remota com URL absoluta).
- **Observabilidade e telemetria no Firebase Crashlytics**:
  - Em `ServicoCroquiOnline.carregarCroquiRemoto`, assegura que qualquer falha (seja HTTP status != 200, exceção de cliente fechado ou erro de parsing) seja registrada com rastreamento de pilha e contexto via `AppLogger.instance.logFalhaSyncOuDownload`.
  - Na camada de interface (`funcoes_home.dart`, `busca_global.dart`, `explorar_view_model.dart`, etc.), quando o croqui não puder ser obtido e a SnackBar de erro de conexão for acionada, emite um relatório explícito com `AppLogger.instance.logFalhaSyncOuDownload`, garantindo que toda ocorrência apareça no painel de problemas do Firebase Crashlytics.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade introduzida -->

### Modified Capabilities
- `transmissao-croqui-online`: Modifica os requisitos de carregamento sob demanda do protobuf `.binarypb` para exigir reporte obrigatório de falhas ao Firebase Crashlytics via `AppLogger`, e preservação do cliente HTTP compartilhado no ciclo de vida de ViewModels.

## Impact

- `frontend/lib/view/view_models/pico_view_model.dart`: Ajuste em `dispose()`.
- `frontend/lib/view/function_library/funcoes_home.dart`: Saneamento do fallback e inclusão de telemetria/report de erro no Crashlytics ao falhar abertura de guia.
- `frontend/lib/services/http/servico_croqui_online.dart`: Garantia de log de falha no download sob demanda com `logFalhaSyncOuDownload`.
- `frontend/test/`: Atualização e adição de testes unitários e de widget cobrindo abertura consecutiva de múltiplos croquis online e validação do envio de relatórios para o Crashlytics.
