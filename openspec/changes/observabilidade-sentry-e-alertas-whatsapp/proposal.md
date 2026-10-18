## Why

Durante a investigação do incidente de resolução de referências legadas de croquis (v0.1.3-beta.8), constatou-se uma lacuna crítica de observabilidade em todo o ecossistema Aresta Climb:
1. O backend serverless (`aresta_backend`, composto por Cloudflare Workers e Supabase Edge Functions) e o portal web (`arestaclimb.com`) não possuíam rastreamento centralizado e estruturado de exceções em tempo real.
2. Erros críticos de aplicativo móvel (`aresta_app`), falhas de deploy/CI nos repositórios da organização (`aresta-climb`) e novos feedbacks/submissões da comunidade não dispunham de notificações ativas instantâneas para a equipe de engenharia.
3. A criação manual ou descentralizada de alertas gera fadiga de notificações caso não haja deduplicação robusta na primeira ocorrência (*First Seen*) e separação clara entre emergências críticas (crashes fatais, picos de erro, queda de serviço, quebra de deploy na `main`) e triagem operacional (novas issues deduplicadas pelo Sentry, feedbacks de usuários via `app-feedback` e novos Pull Requests do `create-pr`).

Adotar o **Sentry (plano Open Source)** integrado ao **GitHub Issues** e a um **Roteador Central de Alertas (`cloudflare/alertas`)** conectado a dois grupos de WhatsApp via **WAHA (WhatsApp HTTP API)** em uma instância gratuita **Google Cloud `e2-micro`** — com fallback automático de e-mail via **Resend (`contato@arestaclimb.com`)** caso o gateway do WhatsApp falhe — garante visibilidade imediata de ponta a ponta com custo operacional zero e sem expor dados sensíveis de usuários em repositórios públicos.

## What Changes

- **Instrumentação Dual Crashlytics + Sentry no `aresta_app`**:
  - Evolução do `AppLogger` (`frontend/lib/services/firebase/app_logger.dart`) para espelhar breadcrumbs (`logInfo`, `logAviso`) e relatórios de erro/crash (`logError`, `logCrash`, `logFalhaSyncOuDownload`) simultaneamente no Firebase Crashlytics e no `sentry_flutter`, preservando o filtro de falhas transitórias de conectividade (`isFalhaConexaoOuTimeout`), o cache offline nativo e a testabilidade determinística via overrides/fakes sem mocks.
- **Cliente Nativo Sentry Envelope e Instrumentação no `aresta_backend` e `arestaclimb.com`**:
  - Criação do módulo compartilhado `relator_sentry.ts` (e seu respectivo fake determinístico `relator_sentry_fake.ts`) utilizando o protocolo HTTP Envelope do Sentry via `fetch` + `waitUntil` (zero dependências externas pesadas).
  - Instrumentação de todos os Cloudflare Workers (`catalogo`, `feedback`, `previa`) e Supabase Edge Functions (`git-proxy`, `create-pr`, `app-feedback`, `discord-feedback`).
  - Criação do módulo de telemetria web `src/telemetria.js` no `arestaclimb.com` para captura de exceções não tratadas (`error`, `unhandledrejection`) no site principal e no editor web (`editor.html`).
- **Roteador Central de Alertas (`aresta_backend/cloudflare/alertas`) com Fallback Resend**:
  - Novo Cloudflare Worker responsável por receber webhooks autenticados do Sentry (`POST /webhook/sentry`) e da organização GitHub `aresta-climb` (`POST /webhook/github`).
  - Roteamento inteligente para dois grupos de uma Comunidade privada no WhatsApp através da API REST do WAHA:
    - **`🚨 Grupo 1 — Emergências`**: Crashes fatais/regressões críticas do Sentry, alertas de pico/velocidade (*Spike Protection*), quedas de *Uptime Monitoring* e falhas de GitHub Actions (`workflow_run.completed` com `conclusion === "failure"` na branch `main` ou tags de release, cobrindo inclusive deploys do `aresta_db`).
    - **`🛠️ Grupo 2 — Bugs & Feedbacks`**: Novas issues abertas em qualquer repositório da organização (`issues.opened`, incluindo issues deduplicadas abertas pelo Sentry na 1ª ocorrência e relatos do `app-feedback`) e novos Pull Requests de submissão de croquis (`pull_request.opened` gerados pelo `create-pr`), enriquecidos automaticamente com o link direto para o evento no Sentry quando presente.
  - **Mecanismo de Fallback de Alta Disponibilidade via Resend**: Caso o envio ao gateway WAHA falhe (timeout, erro HTTP ou sessão desconectada), o Worker dispara automaticamente o alerta formatado por e-mail via API do **Resend** (`alerta@login.arestaclimb.com` $\rightarrow$ `contato@arestaclimb.com`) com aviso de indisponibilidade do WhatsApp, sem gerar recursão de erro no Sentry.
- **Documentação Completa Passo a Passo de Configuração e Infraestrutura**:
  - Criação de guia técnico detalhado (`docs/guia_configuracao_observabilidade_e_alertas.md`) explicando como configurar cada etapa da arquitetura: candidatura e criação de projetos no Sentry Open Source, regras de alerta e integração GitHub Issues (*First Seen*), provisionamento da VM gratuita **GCP `e2-micro`** com Docker + **WAHA (motor NOWEB)** + **Cloudflare Tunnel (`cloudflared`)**, criação da Comunidade e grupos no WhatsApp, configuração do Webhook Organizacional no GitHub e cadastro dos segredos no Cloudflare Workers e Supabase (incluindo Resend).

## Capabilities

### New Capabilities
- `roteador-alertas-whatsapp-e-fallback`: Worker Cloudflare (`cloudflare/alertas`) para recepção autenticada de webhooks do Sentry e do GitHub Organization, classificação e formatação de mensagens para os dois grupos de WhatsApp via gateway WAHA, fallback automático por e-mail via Resend (`contato@arestaclimb.com`) em caso de falha no WhatsApp, e documentação completa passo a passo de provisionamento (incluindo WAHA no GCP `e2-micro`).
- `telemetria-sentry-backend-e-web`: Cliente leve do protocolo Sentry Envelope (`relator_sentry.ts` e fake determinístico `relator_sentry_fake.ts`) para captura assíncrona de erros não tratados e rejeições em Cloudflare Workers (`catalogo`, `feedback`, `previa`), Supabase Edge Functions (`git-proxy`, `create-pr`, `app-feedback`, `discord-feedback`) e aplicação web (`arestaclimb.com`).

### Modified Capabilities
- `padronizacao-logging-applogger`: Extensão do `AppLogger` no `aresta_app` para envio dual de breadcrumbs e erros não-fatais/fatais ao Firebase Crashlytics e ao Sentry (`sentry_flutter`), mantendo cache offline, filtragem de erros de conectividade e cobertura comportamental de 100% com testes espelhados 1:1.

## Impact

- **`aresta_app`**:
  - `frontend/pubspec.yaml` (adição de `sentry_flutter`), `frontend/lib/main.dart` (inicialização do `SentryFlutter.init` em conjunto com o `AppLogger`) e `frontend/lib/services/firebase/app_logger.dart` (+ `app_logger_test.dart`).
- **`aresta_backend` & `aresta_api`**:
  - `aresta_api/openapi/` (contrato dos endpoints de webhook caso aplicável), `supabase/functions/compartilhado/relator_sentry.ts` (+ fake e testes), instrumentação nos Workers `catalogo`, `feedback`, `previa` e nas Edge Functions `git-proxy`, `create-pr`, `app-feedback`, `discord-feedback`, além do novo Worker `cloudflare/alertas/`.
- **`arestaclimb.com`**:
  - `src/telemetria.js` (+ `tests/telemetria.test.js`) integrado às entradas principais do site e do editor web.
- **Documentação & Operações**:
  - Novo guia completo de infraestrutura e operação detalhando a configuração do Sentry, GitHub Org Webhook, Resend e WAHA em instância `e2-micro` do Google Cloud Platform.
