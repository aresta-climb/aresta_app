# isolamento-cliente-http Specification

## Purpose

Padroniza e isola o transporte HTTP de todo o aplicativo através de um cliente encapsulado único com pool de conexões Keep-Alive persistente, impedindo a criação de clientes descartáveis e o encerramento acidental de conexões compartilhadas.

## Requirements

### Requirement: Instância Singleton com Pool Keep-Alive de 120 Segundos
O sistema DEVE (MUST) centralizar todas as requisições de rede na classe `ClienteHttpAresta`, fornecendo uma instância singleton global (`ClienteHttpAresta.instancia`) cujo motor de transporte mantenha conexões TCP/TLS ociosas abertas por 120 segundos (`idleTimeout`) e aplique timeout de conexão de 10 segundos (`connectionTimeout`).

#### Scenario: Reutilização de conexão em navegações espaçadas
- **WHEN** o aplicativo realiza uma requisição HTTP para a CDN e realiza uma nova requisição para o mesmo domínio até 120 segundos depois
- **THEN** o pool de conexões reutiliza o socket TCP/TLS existente sem executar um novo handshake TLS.

#### Scenario: Renovação transparente após período ocioso prolongado
- **WHEN** o aplicativo permanece sem realizar requisições por mais de 120 segundos (ex: 2 horas ocioso) e dispara uma nova requisição
- **THEN** o cliente abre uma nova conexão limpa de forma transparente usando a mesma instância singleton.

### Requirement: Restrição Estrita de Instanciação e Imutabilidade do Ciclo de Vida
O `ClienteHttpAresta` DEVE (MUST) possuir construtor privado e permitir obtenção apenas via singleton `ClienteHttpAresta.instancia` ou via fábrica `ClienteHttpAresta.paraTestes` (exclusiva para testes). A interface pública NÃO DEVE (MUST NOT) expor o método `.close()`, impedindo que qualquer módulo encerre o pool de conexões.

#### Scenario: Impossibilidade de fechamento do cliente por consumidores
- **WHEN** um serviço ou ViewModel é descartado (`dispose`) após realizar requisições de rede
- **THEN** o `ClienteHttpAresta` permanece aberto e operacional para todas as telas subsequentes.

#### Scenario: Injeção de cliente simulado em testes automatizados
- **WHEN** um teste unitário ou de widget precisa interceptar chamadas HTTP
- **THEN** o teste instancia o cliente via `ClienteHttpAresta.paraTestes(mockClient)` e o injeta no serviço ou provedor testado.

### Requirement: Fiscalização Arquitetural Automatizada de Isolamento HTTP
A suíte de testes DEVE (MUST) incluir um teste de arquitetura que inspecione todos os arquivos de `lib/` (exceto `cliente_http_aresta.dart`) e falhe caso detecte importação direta de `package:http/`, uso de `http.Client`, `IOClient` ou `HttpClient`, chamadas a `ClienteHttpAresta.paraTestes` ou invocações de `.close()` em clientes de rede.

#### Scenario: Violação detectada por instanciação direta de cliente HTTP em produção
- **WHEN** qualquer arquivo em `lib/` fora de `cliente_http_aresta.dart` importa `package:http/` ou referencia `http.Client` ou `ClienteHttpAresta.paraTestes`
- **THEN** o teste de arquitetura falha apontando o arquivo e a linha exata da violação.
