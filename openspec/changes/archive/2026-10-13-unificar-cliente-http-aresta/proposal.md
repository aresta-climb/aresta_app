# Proposal

## Why

Atualmente, diversos módulos do aplicativo (`ProvedorImagemAresta`, `EditorDeCroqui`, `OrquestradorFeedback`, `funcoes_configuracoes`, entre outros) instanciam objetos `http.Client()` descartáveis a cada requisição ou operação e os destroem imediatamente com `.close()`. No carregamento de imagens remotas via `ProvedorImagemAresta`, cada miniatura, foto de capa ou mapa abria uma nova conexão TCP e realizava um handshake TLS completo do zero com a CDN (`serving.arestaclimb.com`), descartando o socket ao final e impedindo o reaproveitamento de conexões *HTTP Keep-Alive*. Além disso, a exposição direta de `http.Client` e do método `.close()` já ocasionou bugs onde o fechamento de uma tela encerrava o cliente HTTP compartilhado, quebrando navegações subsequentes.

## What Changes

- **Criação do `ClienteHttpAresta` (`lib/services/http/cliente_http_aresta.dart`)**:
  - Encapsula o cliente HTTP nativo (`IOClient` sobre `HttpClient` do `dart:io`) configurado com `idleTimeout = const Duration(seconds: 120)` (2 minutos de *Keep-Alive*) e `connectionTimeout = const Duration(seconds: 10)`.
  - Possui construtor privado e permite obtenção exclusivamente por dois caminhos:
    1. `ClienteHttpAresta.instancia`: instância singleton compartilhada por todo o aplicativo em produção;
    2. `ClienteHttpAresta.paraTestes(http.Client mock)`: fábrica anotada com `@visibleForTesting` restrita à suíte de testes.
  - **Não expõe o método `.close()`**, tornando impossível por design o encerramento acidental do pool de conexões por qualquer consumidor no aplicativo.
  - Re-exporta os tipos de dados necessários do pacote `http` (`Response`, `Request`, `StreamedResponse`, `MultipartRequest`, `MultipartFile`, `ClientException`, `ByteStream`) ocultando `Client` e `BaseClient`.
- **Migração de todos os consumidores HTTP em `lib/`**:
  - Substituição de todas as referências e parâmetros `http.Client` por `ClienteHttpAresta` em `ProvedorImagemAresta`, `ServicoCroquiOnline`, `SyncService`, `SyncNetwork`, `BaixadorAtualizacoes`, `EditorDeCroqui`, `OrquestradorFeedback`, `FeedbackNetworkService`, `funcoes_configuracoes` e `sync_isolate`, utilizando `ClienteHttpAresta.instancia` como padrão quando um cliente de teste não for injetado.
  - Remoção de todas as chamadas a `.close()` em clientes HTTP espalhadas pelo código de produção.
- **Resiliência e Eliminação de Fallbacks Silenciosos no `ProvedorImagemAresta`**:
  - Adição de timeout explícito no download de mídias remotas e substituição de blocos `catch (_) {}` silenciosos por tratamento e registro rastreável.
- **Teste Arquitetural de Isolamento (`test/architecture/isolamento_cliente_http_test.dart`)**:
  - Garante automaticamente que nenhum arquivo em `lib/` (exceto `cliente_http_aresta.dart`) importe `package:http/`, instancie `http.Client`, `IOClient` ou `HttpClient`, invoque `ClienteHttpAresta.paraTestes` ou chame `.close()` em clientes HTTP.

## Capabilities

### New Capabilities
- `isolamento-cliente-http`: Centralização do transporte HTTP através do `ClienteHttpAresta` com pool Keep-Alive de 120 segundos, proibição de exposição de `http.Client` e `.close()` fora da camada base e fiscalização automatizada via teste de arquitetura.

### Modified Capabilities
- `transmissao-croqui-online`: Reutilização da conexão HTTP persistente (`ClienteHttpAresta`) entre o download de `.binarypb` e a resolução de imagens remotas no `ProvedorImagemAresta`, eliminando handshakes TLS redundantes e descartes prematuros de conexão.

## Impact

- **Código Afetado (`frontend/lib/`)**:
  - `lib/services/http/cliente_http_aresta.dart` (novo)
  - `lib/widgets/provedor_imagem_aresta.dart`
  - `lib/services/http/servico_croqui_online.dart`
  - `lib/services/http/sync_service.dart`
  - `lib/services/http/sync_rede.dart`
  - `lib/services/http/sync_isolate.dart`
  - `lib/services/http/baixador_atualizacoes.dart`
  - `lib/services/editor_croqui.dart`
  - `lib/services/feedback/feedback_network_service.dart`
  - `lib/application_managers/feedback/orquestrador_feedback.dart`
  - `lib/view/function_library/funcoes_configuracoes.dart`
  - `lib/services/firebase/app_logger.dart`
- **Testes Afetados (`frontend/test/`)**:
  - `test/architecture/isolamento_cliente_http_test.dart` (novo)
  - `test/services/http/cliente_http_aresta_test.dart` (novo)
  - Adequação dos testes unitários existentes que injetam mocks de cliente HTTP para utilizarem `ClienteHttpAresta.paraTestes(...)`.
