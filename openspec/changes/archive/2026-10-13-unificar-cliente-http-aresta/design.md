# Design

## Context

Veja `proposal.md` para a motivação. Atualmente, `package:http/http.dart` é importado em 11 arquivos dentro de `frontend/lib/`. A maioria dos serviços instancia `http.Client()` manualmente e invoca `.close()` ao término de operações pontuais ou no `dispose` de ViewModels. Esse padrão impede o reaproveitamento do pool de sockets TCP/TLS (*HTTP Keep-Alive*) e expõe o sistema ao fechamento prematuro de clientes compartilhados.

## Goals / Non-Goals

**Goals:**
- Encapsular 100% do acesso a `package:http` no módulo `lib/services/http/cliente_http_aresta.dart`.
- Configurar o pool de conexões nativo (`dart:io HttpClient` via `IOClient`) com `idleTimeout = const Duration(seconds: 120)` e `connectionTimeout = const Duration(seconds: 10)`.
- Garantir em tempo de compilação que nenhum consumidor possa fechar o cliente HTTP (ausência do método `.close()` em `ClienteHttpAresta`).
- Garantir via teste arquitetural que `http.Client` nunca seja exposto ou instanciado fora de `cliente_http_aresta.dart` e que `ClienteHttpAresta.paraTestes` seja invocado apenas em `test/`.
- Eliminar blocos `catch (_) {}` silenciosos no `ProvedorImagemAresta`.

**Non-Goals:**
- Alterar scripts de deploy ou configurações de CDN no repositório `aresta_db`.
- Modificar o protocolo de comunicação WebSocket de Live Reload (`WebSocket` do `dart:io`).

## Decisions

### 1. Wrapper Encapsulado (`ClienteHttpAresta`) em vez de implementar `http.Client`
- **Decisão**: `ClienteHttpAresta` será uma classe própria que compõe um `http.Client _inner` privado, expondo apenas os métodos de requisição (`get`, `post`, `head`, `send`) e **omitindo deliberadamente o método `.close()`**.
- **Racional**: Se `ClienteHttpAresta` implementasse a interface `http.Client`, seria obrigado a expor `void close()`, mantendo a possibilidade de chamadas acidentais. Ao omitir `.close()` da interface pública e proibir o tipo `http.Client` fora de `cliente_http_aresta.dart`, o erro torna-se impossível em tempo de compilação.
- **Re-exportação seletiva**: `cliente_http_aresta.dart` fará `export 'package:http/http.dart' show Response, Request, StreamedResponse, MultipartRequest, MultipartFile, ClientException, BaseRequest, ByteStream;`, permitindo que serviços como `FeedbackNetworkService`, `SyncNetwork` e `AppLogger` manipulem payloads e exceções HTTP sem importar `package:http/http.dart` diretamente.

### 2. Duas Únicas Formas de Construção
- **Decisão**:
  1. `static final ClienteHttpAresta instancia = ClienteHttpAresta._(_criarClientePadrao());` — singleton preguiçoso e imutável por Isolate.
  2. `@visibleForTesting factory ClienteHttpAresta.paraTestes(http.Client clienteMock) => ClienteHttpAresta._(clienteMock);` — fábrica exclusiva para injeção de `MockClient` ou fakes em testes.
- **Racional**: Elimina o acoplamento temporal de métodos `configurar()` e garante que qualquer classe cujo parâmetro opcional `ClienteHttpAresta? cliente` seja omitido utilize automaticamente `ClienteHttpAresta.instancia` sem risco de estado nulo ou inconsistente.

### 3. Keep-Alive (`idleTimeout`) de 120 Segundos
- **Decisão**: Configurar o `HttpClient` subjacente com `idleTimeout = const Duration(seconds: 120)` e `connectionTimeout = const Duration(seconds: 10)`.
- **Racional**: O padrão do Dart (15s) fecha o socket enquanto o escalador lê a descrição de um setor ou analisa o resumo do pico (tipicamente 30s a 90s), exigindo novo handshake TLS ao abrir a próxima foto ou mapa. Com 120s, toda a sessão de leitura de um croqui online reutiliza o mesmo socket aquecido. Caso o aplicativo fique horas ocioso, o `dart:io` fecha os sockets após 120s de inatividade e abre novos transparentemente quando uma nova requisição chegar.

### 4. Comportamento em Background Isolates (`sync_isolate.dart`)
- **Decisão**: O `downloadIsolateMain` também utilizará `ClienteHttpAresta.instancia` (ou um `ClienteHttpAresta?` injetado).
- **Racional**: No modelo de memória do Dart, campos `static` são isolados por *Isolate*. Portanto, acessar `ClienteHttpAresta.instancia` dentro do Isolate de sincronização instancia um pool exclusivo para aquele Isolate, que é automaticamente coletado pelo sistema operacional quando o Isolate se encerra ao final do download.

### 5. Fiscalização via Teste de Arquitetura (`isolamento_cliente_http_test.dart`)
- **Decisão**: Criar `frontend/test/architecture/isolamento_cliente_http_test.dart` nos moldes de `isolamento_logs_arquitetura_test.dart`.
- **Regras verificadas sobre todos os arquivos `.dart` em `lib/` (exceto `lib/services/http/cliente_http_aresta.dart`)**:
  1. Proibido `import 'package:http/` ou `import "package:http/`;
  2. Proibido referenciar `http.Client`, `IOClient(` ou `HttpClient(`;
  3. Proibido invocar `ClienteHttpAresta.paraTestes`;
  4. Proibido invocar `.close()` em clientes de rede.

## Risks / Trade-offs

- **[Risco] Servidor remoto ou NAT de operadora encerrar conexão ociosa antes de 120s** → **Mitigação**: O `HttpClient` nativo do `dart:io` detecta automaticamente sockets que receberam EOF ao enviar uma nova requisição `GET` e abre uma nova conexão TCP/TLS de forma transparente.
- **[Risco] Testes legados passando `http.Client` para construtores de serviços** → **Mitigação**: Atualizar os helpers e mocks nos testes unitários para envolverem seus `MockClient` com `ClienteHttpAresta.paraTestes(mockClient)`.
