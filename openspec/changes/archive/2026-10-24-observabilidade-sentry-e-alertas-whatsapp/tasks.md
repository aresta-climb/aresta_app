# Tasks

## 1. Dual-Logging Crashlytics + Sentry no `aresta_app`

- [x] 1.1 Adicionar a dependência `sentry_flutter` no `frontend/pubspec.yaml` e verificar a resolução limpa de pacotes com `flutter pub get`.
- [x] 1.2 Escrever os testes unitários em `frontend/test/services/firebase/app_logger_test.dart` (fase *Red* do TDD) validando o envio dual de breadcrumbs (`logInfo`, `logAviso`) e exceções (`logError`, `logCrash`, `logFalhaSyncOuDownload`) para o Crashlytics e para o Sentry via overrides determinísticos, bem como o bloqueio de envio para falhas reconhecidas por `isFalhaConexaoOuTimeout`.
- [x] 1.3 Implementar o suporte dual ao Sentry em `frontend/lib/services/firebase/app_logger.dart` e a inicialização condicional por `SENTRY_DSN` em `frontend/lib/main.dart` (fase *Green/Refactor*), verificando 100% de cobertura comportamental com `flutter test test/services/firebase/app_logger_test.dart --coverage` e aprovação do teste arquitetural `flutter test test/architecture/isolamento_logs_arquitetura_test.dart`.
- [x] 1.4 Atualizar a documentação do módulo de logging no `frontend/README.md` descrevendo o funcionamento do dual-logging (Crashlytics + Sentry) e a fila offline.

## 2. Cliente Sentry Envelope e Instrumentação no `aresta_backend`

- [x] 2.1 Criar a biblioteca fake determinística `supabase/functions/compartilhado/relator_sentry_fake.ts` e seu respectivo teste espelhado `supabase/functions/compartilhado/relator_sentry_fake.test.ts` no repositório `aresta_backend`, verificando que todos os testes do fake passam.
- [x] 2.2 Escrever os testes comportamentais em `supabase/functions/compartilhado/relator_sentry.test.ts` (fase *Red*) cobrindo parsing de DSN, montagem do payload Sentry Envelope com frames de stack trace, sanitização de cabeçalhos sensíveis (`Authorization`, `Cookie`, `x-api-key`), agendamento via `waitUntil` e modo *no-op* quando `SENTRY_DSN` estiver ausente.
- [x] 2.3 Implementar `supabase/functions/compartilhado/relator_sentry.ts` (fase *Green/Refactor*) e verificar aprovação integral e 100% de cobertura nos testes unitários.
- [x] 2.4 Instrumentar os Cloudflare Workers (`cloudflare/catalogo`, `cloudflare/feedback`, `cloudflare/previa`) e as Supabase Edge Functions (`git-proxy`, `create-pr`, `app-feedback`, `discord-feedback`) com o `relator_sentry.ts`, atualizando seus respectivos arquivos `.test.ts` usando `RelatorSentryFake` e verificando que toda a suíte de testes do `aresta_backend` passa com 100% de cobertura.

## 3. Telemetria de Exceções no Portal Web `arestaclimb.com`

- [x] 3.1 Escrever os testes unitários em `src/telemetria.test.js` no repositório `arestaclimb.com` (fase *Red*) validando a captura de eventos globais `error` e `unhandledrejection`, o envio de envelope ao Sentry quando `VITE_SENTRY_DSN` estiver definido e a filtragem de falhas de rede quando o navegador estiver offline (`navigator.onLine === false`).
- [x] 3.2 Implementar o módulo `src/telemetria.js` e integrá-lo nos pontos de entrada do site principal e do editor web (`editor.html`), verificando que `npx vitest run --coverage` passa com 100% de cobertura no novo módulo.

## 4. Roteador Central de Alertas (`cloudflare/alertas`) com WAHA e Fallback Resend

- [x] 4.1 Criar os fakes determinísticos de fronteira para o gateway WAHA e para a API do Resend (`cliente_notificacao_fake.ts` + `cliente_notificacao_fake.test.ts`) em `aresta_backend/cloudflare/alertas/`, verificando que os testes de contrato do fake passam.
- [x] 4.2 Escrever os testes comportamentais do Worker `cloudflare/alertas` (`index.test.ts` - fase *Red*) cobrindo:
  - Validação criptográfica HMAC-SHA256 para `POST /webhook/sentry` e `POST /webhook/github` (rejeitando assinaturas inválidas com HTTP `401`);
  - Roteamento de alertas críticos do Sentry (Crash fatal, Spike, Uptime) e falhas de GitHub Actions (`workflow_run` com `conclusion === "failure"` na branch `main` ou tags de release, incluindo deploys do `aresta_db`) para `🚨 Grupo 1 — Emergências`;
  - Roteamento de novas issues (`issues.opened`, extraindo o link do Sentry quando presente) e novos Pull Requests (`pull_request.opened`) para `🛠️ Grupo 2 — Bugs & Feedbacks`;
  - Acionamento automático do fallback de e-mail via API do **Resend** (`alerta@login.arestaclimb.com` $\rightarrow$ `contato@arestaclimb.com`) exclusivamente quando o envio ao WAHA falhar (timeout ou status não-2xx), sem gerar loop recursivo no Sentry.
- [x] 4.3 Implementar o Cloudflare Worker `aresta_backend/cloudflare/alertas/` (`wrangler.jsonc`, `src/index.ts` e formatadores de mensagem em português) e verificar 100% de cobertura comportamental na suíte de testes do Worker.

## 5. Documentação Completa Passo a Passo de Configuração e Infraestrutura

- [x] 5.1 Criar o documento técnico detalhado `docs/guia_configuracao_observabilidade_e_alertas.md` (e referenciá-lo nos `README.md` de `aresta_app` e `aresta_backend`) contendo instruções passo a passo para:
  - Solicitação do plano **Sentry for Open Source** e criação dos projetos (`aresta-app`, `aresta-backend`, `aresta-web`, `aresta-editor`);
  - Configuração da integração oficial **Sentry $\leftrightarrow$ GitHub** para abertura automática de Issue na 1ª ocorrência (*First Seen*) no repositório correspondente sem exposição de PII, e envio de webhook de emergência (Fatal/Spike/Uptime) para `/webhook/sentry`;
  - Provisionamento passo a passo da VM gratuita **Google Cloud `e2-micro` (Always Free)** em `us-central1`/`us-east1`, instalação do Docker Compose com **WAHA (`devlikeapro/waha`, motor `NOWEB`)** e **Cloudflare Tunnel (`cloudflared`)**, pareamento via QR Code e obtenção dos IDs (`@g.us`) dos dois grupos da Comunidade no WhatsApp;
  - Configuração do **Webhook Organizacional** na organização `aresta-climb` do GitHub (`issues`, `pull_request`, `workflow_run`) apontando para `/webhook/github`;
  - Configuração da chave da API do **Resend** (`RESEND_API_KEY` usando o domínio verificado `login.arestaclimb.com` com destino `contato@arestaclimb.com`) e cadastro de todos os secrets via `wrangler secret put` e `supabase secrets set`.
- [x] 5.2 Revisar todos os comandos, arquivos de exemplo (`docker-compose.yml`, comandos `gcloud`, `wrangler` e `curl` de teste de webhook) descritos no guia para garantir que estão completos, reproduzíveis e em português brasileiro.
