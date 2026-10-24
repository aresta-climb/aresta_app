# telemetria-sentry-backend-e-web Specification

## Purpose

Garantir captura, formatação e envio assíncrono de exceções não tratadas e erros operacionais nos serviços serverless do `aresta_backend` (Cloudflare Workers e Supabase Edge Functions) e no portal web `arestaclimb.com` para o Sentry utilizando o protocolo HTTP Envelope leve e bibliotecas de fake determinísticas.

## Requirements

### Requirement: Cliente Nativo Sentry Envelope para Ambientes Serverless
O módulo compartilhado `relator_sentry.ts` SHALL converter objetos `Error` (incluindo `stack`, tags de serviço, ambiente e contexto da requisição HTTP) no formato oficial de envelope do Sentry e enviá-los via `fetch` para o endpoint `/api/<project_id>/envelope/` extraído do `SENTRY_DSN`, sem bloquear a resposta ao cliente quando um contexto `waitUntil` for fornecido.

#### Scenario: Envio assíncrono de exceção com stack trace estruturado
- **WHEN** `relatarErroSentry` for invocado com um `Error`, `SENTRY_DSN` válido, nome do serviço e contexto de execução (`waitUntil`)
- **THEN** o cliente DEVE agendar em `waitUntil` uma requisição `POST` para a URL de envelope do Sentry contendo os frames de pilha extraídos e metadados do serviço.

#### Scenario: Desativação silenciosa quando SENTRY_DSN não estiver configurado
- **WHEN** `relatarErroSentry` for invocado com `SENTRY_DSN` vazio ou indefinido (como em desenvolvimento local sem chave)
- **THEN** o cliente NÃO DEVE realizar chamadas de rede nem lançar exceções secundárias.

### Requirement: Instrumentação Padronizada em Cloudflare Workers e Supabase Edge Functions
Todos os Cloudflare Workers (`catalogo`, `feedback`, `previa`) e Supabase Edge Functions (`git-proxy`, `create-pr`, `app-feedback`, `discord-feedback`) SHALL interceptar falhas críticas de execução e reportá-las ao Sentry através do `relator_sentry.ts` antes de retornar a resposta HTTP de erro (`500`/`502`), preservando a privacidade de credenciais e tokens nos cabeçalhos capturados.

#### Scenario: Exceção não tratada em Worker ou Edge Function é reportada ao Sentry
- **WHEN** ocorrer uma exceção inesperada durante o processamento de uma requisição em qualquer Worker ou Edge Function instrumentado
- **THEN** o manipulador DEVE registrar o erro via `relatarErroSentry` com a tag `servico` correspondente, omitir cabeçalhos sensíveis (`Authorization`, `Cookie`, `x-api-key`) e retornar a resposta de erro padronizada.

### Requirement: Biblioteca Fake Determinística para Testes do Relator Sentry
O backend SHALL disponibilizar uma biblioteca fake determinística (`relator_sentry_fake.ts`), acompanhada de sua suíte de testes espelhada (`relator_sentry_fake.test.ts`), que captura em memória os envelopes enviados e permite simular falhas de rede sem realizar conexões externas durante os testes automatizados.

#### Scenario: Inspeção de erro capturado pelo Fake em teste de fronteira
- **WHEN** um Worker ou Edge Function for executado em ambiente de teste injetando o `RelatorSentryFake` e sofrer uma exceção interna
- **THEN** o `RelatorSentryFake` DEVE armazenar o evento com mensagem, pilha de execução e tags para verificação comportamental pelo teste.

### Requirement: Captura de Exceções Não Tratadas no Portal Web e Editor Online
O portal `arestaclimb.com` (incluindo a página principal e `editor.html`) SHALL inicializar o módulo `src/telemetria.js` para escutar eventos globais `error` e `unhandledrejection` do navegador e encaminhá-los ao projeto `aresta-web` no Sentry quando `VITE_SENTRY_DSN` estiver definido, ignorando erros transitórios de queda de conexão do usuário.

#### Scenario: Captura de erro de runtime no navegador em produção
- **WHEN** ocorrer um erro JavaScript não tratado ou `unhandledrejection` no navegador com `VITE_SENTRY_DSN` configurado
- **THEN** o módulo `telemetria.js` DEVE enviar o relatório de exceção para o Sentry com a URL da página e o User-Agent.

#### Scenario: Ignorar falha de fetch por desconexão offline do navegador
- **WHEN** ocorrer uma rejeição de Promise causada exclusivamente por ausência de rede do cliente (`Failed to fetch` / `NetworkError` com `navigator.onLine === false`)
- **THEN** o módulo `telemetria.js` NÃO DEVE reportar o evento como bug da aplicação no Sentry.
