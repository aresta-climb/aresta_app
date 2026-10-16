# Tasks

## 1. Camada Base `ClienteHttpAresta` (TDD)

- [x] 1.1 Criar o teste unitário `frontend/test/services/http/cliente_http_aresta_test.dart` (Red) validando o singleton `ClienteHttpAresta.instancia`, a fábrica `ClienteHttpAresta.paraTestes`, o encaminhamento dos métodos HTTP (`get`, `post`, `head`, `send`), a configuração de `idleTimeout` de 120 segundos e a ausência do método `.close()`, verificando que o teste falha antes da implementação.
- [x] 1.2 Implementar `frontend/lib/services/http/cliente_http_aresta.dart` (Green) com docstrings detalhadas em português, construtor privado, `IOClient` com `idleTimeout = const Duration(seconds: 120)` e `connectionTimeout = const Duration(seconds: 10)`, re-exportação seletiva dos tipos de dados do pacote `http` (ocultando `Client` e `BaseClient`) e validar com `flutter test test/services/http/cliente_http_aresta_test.dart`.
- [x] 1.3 Atualizar `frontend/lib/services/README.md` documentando a arquitetura do `ClienteHttpAresta` e suas regras de ciclo de vida e isolamento.

## 2. Migração do `ProvedorImagemAresta` e Eliminação de Fallbacks Silenciosos (TDD)

- [x] 2.1 Atualizar `frontend/test/widgets/provedor_imagem_aresta_test.dart` (Red) para injetar `ClienteHttpAresta.paraTestes`, validar que múltiplas resoluções consecutivas reutilizam o mesmo cliente sem fechá-lo e validar o timeout e registro de erros sem `catch` vazio.
- [x] 2.2 Refatorar `frontend/lib/widgets/provedor_imagem_aresta.dart` (Green) para receber `ClienteHttpAresta? clienteHttp` (usando `ClienteHttpAresta.instancia` como padrão), remover `client.close()`, aplicar timeout explícito nas requisições de imagem e substituir blocos `catch (_) {}` silenciosos por tratamento rastreável, validando com `flutter test test/widgets/provedor_imagem_aresta_test.dart`.
- [x] 2.3 Atualizar `frontend/lib/widgets/README.md` refletindo o uso do `ClienteHttpAresta` compartilhado pelo `ProvedorImagemAresta`.

## 3. Migração dos Serviços de Sincronização, Croqui Online e Editor (TDD)

- [x] 3.1 Atualizar os testes em `frontend/test/services/http/` (`servico_croqui_online_test.dart`, `sync_service_test.dart`, `sync_rede_test.dart`, `sync_isolate_test.dart`, `baixador_atualizacoes_test.dart`) e `frontend/test/services/editor_croqui_test.dart` (Red) para usarem `ClienteHttpAresta.paraTestes` e removerem expectativas de fechamento do cliente HTTP.
- [x] 3.2 Refatorar `servico_croqui_online.dart`, `sync_service.dart`, `sync_rede.dart`, `sync_isolate.dart`, `baixador_atualizacoes.dart` e `editor_croqui.dart` (Green) para substituírem `package:http/http.dart` e `http.Client` por `ClienteHttpAresta`, removendo todos os métodos/chamadas `.close()` de cliente HTTP e verificando que todos os testes do grupo passam com `flutter test`.

## 4. Migração de Feedback, Configurações e Logger (TDD)

- [x] 4.1 Atualizar os testes `orquestrador_feedback_test.dart`, `feedback_network_service_test.dart`, `funcoes_configuracoes_test.dart` e `app_logger_test.dart` (Red) para utilizarem `ClienteHttpAresta.paraTestes` e os tipos re-exportados por `cliente_http_aresta.dart`.
- [x] 4.2 Refatorar `orquestrador_feedback.dart`, `feedback_network_service.dart`, `funcoes_configuracoes.dart` e `app_logger.dart` (Green) para consumirem exclusivamente `cliente_http_aresta.dart`, eliminando importações diretas de `package:http/http.dart` e chamadas a `httpClient.close()`, validando com `flutter test`.

## 5. Teste Arquitetural de Isolamento e Verificação Global

- [x] 5.1 Criar `frontend/test/architecture/isolamento_cliente_http_test.dart` verificando que nenhum arquivo em `lib/` (exceto `cliente_http_aresta.dart`) importa `package:http/`, referencia `http.Client`, `IOClient` ou `HttpClient(`, invoca `ClienteHttpAresta.paraTestes` ou chama `.close()` em clientes HTTP, e validar sua execução com `flutter test test/architecture/isolamento_cliente_http_test.dart`.
- [x] 5.2 Executar `flutter analyze` e a suíte completa de testes (`flutter test`) garantindo 0 avisos de linter e 100% de aprovação nos testes unitários, de widget e de arquitetura.
