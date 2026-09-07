## Why

Na versão `0.2.4+66` foram observadas 3 ocorrências de crash no Firebase Crashlytics com alto impacto ou diagnósticos enganosos:
1. Um falso positivo de crash fatal originado por `HTTP 504 Gateway Timeout` ao baixar webp de setor no `sync_isolate`, onde o `AppLogger` não reconheceu o status HTTP como transitório e o Crashlytics herdou indevidamente a stack trace da thread principal (`_writeConfig`). Além disso, o download falhava de imediato sem qualquer mecanismo de retentativa resiliente para erros transitórios de rede/servidor.
2. Uma quebra por `Null check operator used on a null value` durante `GoogleMapController._connectStreams` e renderização de marcadores em dispositivos OnePlus com Android 11.
3. Uma quebra por `Null check operator used on a null value` em `ButtonStyle.merge` durante interações com botões/menus em variações de estado de tema.

Esta mudança corrige essas causas raízes seguindo rigorosamente os preceitos de `PRINCIPIOS.md`:
- **Tudo em Português**: Nomes de variáveis, propriedades, docstrings e testes 100% em português brasileiro.
- **TDD Obrigatório & Widget Tests em Primeiro Lugar**: Escrita prévia de testes de interface e de unidade espelhados em `test/` antes do código de produção.
- **100% de Cobertura de Testes**: Garantia de cobertura total nos arquivos e fluxos afetados.
- **Simplicidade & Anti-Abstração**: Sem abstrações prematuras; retentativas com espera progressiva e fallbacks seguros e diretos.
- **Documentação Contínua**: Docstrings explicativas em blocos `///` detalhando a intenção técnica.

## What Changes

- **Isolate Rastreamento de Pilha, Retentativa Resiliente & Classificação de Rede (`sync_isolate` / `AppLogger`)**:
  - `downloadAtomic` no `sync_isolate.dart` passa a implementar **mecanismo de retentativas inteligentes (até 3 tentativas)** com recuo progressivo (backoff) para erros transitórios de rede (HTTP 502, 503, 504, 429 e timeouts), recuperando downloads que sofreram oscilações temporárias de conexão ou CDN.
  - Concorrência controlada no download de múltiplos arquivos externos para prevenir sobrecarga de sockets e saturação de largura de banda móvel.
  - `DownloadIsolateResult` passa a transportar a propriedade `rastreamentoPilha` capturada no momento da falha definitiva dentro do isolate.
  - `SyncService` reconstrói a pilha via `StackTrace.fromString` e repassa para o `AppLogger`.
  - `AppLogger.isFalhaConexaoOuTimeout` passa a reconhecer códigos de erro HTTP transitórios (502, 503, 504) e expressões de gateway timeout, categorizando-os como `fatal: false`.
- **Defensiva em Marcadores e Câmera de Mapa (`mapa_marker` / `mapa_global_functions`)**:
  - Remoção de force-unwraps (`!`) na conversão de `ByteData` para `Uint8List` e no acesso ao mapa de ícones (`textIcons`), usando fallback direto para `BitmapDescriptor.defaultMarker`.
  - Tratamento defensivo contra payloads nativos nulos ou incompletos na inicialização de streams de câmera em dispositivos OEM (OnePlus Android 11).
- **Consistência de Temas de Botões e Menus (`main.dart`)**:
  - Definição explícita de `iconButtonTheme`, `menuButtonTheme` e `popupMenuTheme` com estilos base no `ThemeData` (Claro e Escuro) para evitar que `ButtonStyle.merge` atue sobre referências nulas.
- **Documentação em Português**:
  - Todas as funções, métodos, classes e arquivos de teste criados ou modificados conterão docstrings `///` em português explicando o porquê das decisões.

## Capabilities

### New Capabilities
- `rastreamento-falhas-isolates-rede`: Mecanismo de retentativas automáticas com espera progressiva para falhas transitórias de download (HTTP 502/503/504, 429 e timeouts), captura e propagação de rastreamento de pilha (`rastreamentoPilha`) de isolates para o processo principal e classificação correta de erros de infraestrutura como não-fatais.
- `estabilidade-mapa-marcadores`: Fallbacks diretos e eliminação de force-unwraps (`!`) na conversão de buffers gráficos e marcações no mapa, prevenindo crashes em ambientes restritos de memória ou com interferência nativa OEM.
- `temas-botoes-consistencia`: Padronização de temas base de botões e menus (`IconButton`, `PopupMenuButton`, `MenuAnchor`) garantindo que mesclagens de estilo nunca recebam valores nulos.

### Modified Capabilities
<!-- Nenhuma especificação existente teve requisitos funcionais alterados -->

## Impact

- **Código Afetado**:
  - `frontend/lib/services/http/sync_isolate.dart`
  - `frontend/lib/services/http/sync_service.dart`
  - `frontend/lib/services/firebase/app_logger.dart`
  - `frontend/lib/view_functions/mapa/mapa_marker.dart`
  - `frontend/lib/view_functions/mapa/mapa_global_functions.dart`
  - `frontend/lib/main.dart`
- **Testes Criados / Atualizados (Estrutura Espelhada em `frontend/test/`)**:
  - `frontend/test/services/firebase/app_logger_test.dart`
  - `frontend/test/services/http/sync_isolate_test.dart`
  - `frontend/test/services/http/sync_service_test.dart`
  - `frontend/test/view_functions/mapa/mapa_marker_test.dart`
  - `frontend/test/view_functions/mapa/mapa_global_functions_test.dart`
  - `frontend/test/widgets/temas_botoes_test.dart`
- **Conformidade com PRINCIPIOS.md**:
  - 100% em português (variáveis, métodos, docstrings, especificações).
  - TDD com Widget Tests em primeiro lugar e 100% de cobertura nos métodos alterados.
