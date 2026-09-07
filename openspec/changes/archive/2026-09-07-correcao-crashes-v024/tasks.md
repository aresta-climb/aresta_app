## 1. Falha 3 - Consistência de Temas para Botões e Menus (Widget Tests Primeiro - Princípios IV e V)

- [x] 1.1 [TDD Red] Escrever testes de widget em `frontend/test/widgets/temas_botoes_test.dart` renderizando `IconButton`, `PopupMenuButton` e botões de feedback sob temas Claro e Escuro, acionando estados de clique para reproduzir a falha de `ButtonStyle.merge` em referências nulas
- [x] 1.2 [TDD Green] Configurar estilos base completos para `iconButtonTheme`, `menuButtonTheme` e `popupMenuTheme` no `ThemeData` (Claro e Escuro) em `frontend/lib/main.dart`
- [x] 1.3 [Documentação] Adicionar docstrings `///` em português brasileiro em `main.dart` explicando a obrigatoriedade dos estilos base de tema para prevenir falhas de fusão em widgets do Material 3

## 2. Falha 1 - Estabilidade de Marcadores e Streams de Mapa (TDD e Defensiva)

- [x] 2.1 [TDD Red] Escrever testes em `frontend/test/view_functions/mapa/mapa_marker_test.dart` simulando falha de buffer gráfico (`image.toByteData()` retornando nulo) na geração de marcadores
- [x] 2.2 [TDD Green] Eliminar force-unwraps (`!`) em `frontend/lib/view_functions/mapa/mapa_marker.dart`, retornando fallback seguro para `BitmapDescriptor.defaultMarker`
- [x] 2.3 [TDD Red] Escrever testes em `frontend/test/view_functions/mapa/mapa_global_functions_test.dart` cobrindo busca de marcadores com id inexistente no mapa `textIcons`
- [x] 2.4 [TDD Green] Atualizar `frontend/lib/view_functions/mapa/mapa_global_functions.dart` substituindo `textIcons[id]!` por fallback seguro e adicionar guarda defensiva em listeners de câmera em `mapa_global.dart`
- [x] 2.5 [Documentação] Incluir docstrings `///` em português em todas as funções de criação de marcadores e manipulação de mapas modificadas

## 3. Falha 2 - Retentativas Resilientes, Rastreamento de Pilha e AppLogger (TDD)

- [x] 3.1 [TDD Red] Escrever testes unitários em `frontend/test/services/firebase/app_logger_test.dart` cobrindo identificação de strings e códigos de erro HTTP 504, 502, 503, Gateway Timeout e garantindo que `logFalhaSyncOuDownload` registre com `fatal: false`
- [x] 3.2 [TDD Green] Atualizar `AppLogger.isFalhaConexaoOuTimeout` em `frontend/lib/services/firebase/app_logger.dart` para reconhecer falhas transitórias de gateway/CDN
- [x] 3.3 [TDD Red] Escrever testes em `frontend/test/services/http/sync_isolate_test.dart` cobrindo: a) recuperação com sucesso na 2ª tentativa após erro transitório (504/timeout), e b) envio de `rastreamentoPilha` preenchido após esgotar todas as tentativas
- [x] 3.4 [TDD Green] Implementar laço de retentativas inteligentes (até 3 tentativas) com espera progressiva em `downloadAtomic` de `frontend/lib/services/http/sync_isolate.dart`, adicionando o campo `rastreamentoPilha` ao `DownloadIsolateResult`
- [x] 3.5 [TDD Red] Escrever testes em `frontend/test/services/http/sync_service_test.dart` validando que `SyncService` reconstrói a pilha com `StackTrace.fromString` e a repassa ao `AppLogger`
- [x] 3.6 [TDD Green] Atualizar o processamento de `DownloadIsolateResult` em `frontend/lib/services/http/sync_service.dart` para repassar o `StackTrace` reconstruído
- [x] 3.7 [Documentação] Documentar detalhadamente em português com blocos `///` em `sync_isolate.dart`, `sync_service.dart` e `app_logger.dart` o fluxo de retentativas resilientes e transporte do rastreamento de pilha

## 4. Validação Geral, Cobertura e Regressão (Princípios I, III e IV)

- [x] 4.1 Executar a suíte de testes completa do aplicativo (`flutter test`) garantindo 100% de sucesso
- [x] 4.2 Executar testes com relatório de cobertura (`flutter test --coverage`) e certificar 100% de cobertura nos métodos alterados
- [x] 4.3 Executar a análise estática (`flutter analyze`) para garantir ausência de erros, warnings de linter e cumprimento das diretrizes de idioma e estilo
