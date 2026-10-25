# Proposal

## Why

O envio de alertas operacionais via WhatsApp através do gateway WAHA exige a manutenção contínua de um número telefônico dedicado (eSIM pré-pago ou assinatura mensal) para evitar riscos de bloqueio em números pessoais pela Meta. Adicionar suporte nativo a **Webhooks Oficiais do Discord** (com menção `@everyone` para garantir notificações push sonoras e badge numérico no celular) como canal primário — mantendo a integração já construída do WAHA (`waha.arestaclimb.com`) pronta em *standby* via variáveis de ambiente e o fallback automático por e-mail via **Resend** — permite operar os alertas imediatamente a custo zero e sem dependência de operadoras móveis, preservando a possibilidade de ativar ou alternar para o WhatsApp a qualquer momento sem alterar código.

## What Changes

- **Suporte Dual / Priorizado a Discord Webhooks e WAHA no `aresta-alertas-worker` (`aresta_backend/cloudflare/alertas`)**:
  - Adição do cliente HTTP `ClienteDiscordHttp` (`InterfaceClienteDiscord`) e do fake determinístico espelhado (`ClienteDiscordFake` em `cliente_notificacao_fake.ts` + testes unitários) para envio de mensagens formatadas aos canais `#🚨-emergencias` (`DISCORD_WEBHOOK_EMERGENCIAS_URL`) e `#🛠️-bugs-e-feedbacks` (`DISCORD_WEBHOOK_BUGS_URL`).
  - Formatação otimizada para notificações push móveis: a primeira linha traz o resumo direto do problema (*gist*) e a menção `@everyone` é posicionada no **rodapé (final)** da mensagem para acionar push sonoro e contador visual vermelho (`badge`) sem truncar o preview da notificação.
  - Preservação integral do suporte ao gateway WAHA (`WAHA_BASE_URL`, `WAHA_API_KEY`, `WHATSAPP_GRUPO_EMERGENCIAS_ID`, `WHATSAPP_GRUPO_BUGS_ID`) em *standby*: o roteador despacha para o(s) canal(is) configurado(s) no ambiente (`CANAL_ALERTAS_ATIVO`: `"discord"`, `"whatsapp"` ou `"ambos"`) e aciona o fallback de e-mail via **Resend (`contato@arestaclimb.com`)** caso os canais primários configurados falhem.
- **Criação Automática de GitHub Issues de Emergência via GitHub App (`Aresta Climb Bot`) e Deduplicação**:
  - Quando uma emergência ocorre sem uma GitHub Issue prévia (Spike/Uptime/Crash Fatal no Sentry ou falha de `workflow_run` no GitHub Actions em `main` / `v*`), o próprio Worker autentica via GitHub App (`ARESTA_CLIMB_BOT_GITHUB_APP_CLIENT_ID`, `ARESTA_CLIMB_BOT_GITHUB_APP_PRIVATE_KEY`, `ARESTA_CLIMB_BOT_GITHUB_APP_INSTALLATION_ID`) e abre automaticamente uma Issue com a label `emergencia` no repositório correspondente da organização `aresta-climb`, incluindo o link da Issue na notificação enviada ao canal `#🚨-emergencias`.
  - Suporte a abertura e reabertura (`opened` e `reopened`) de Issues e Pull Requests: na abertura de uma Issue (`issues.opened`), se ela possuir a label `emergencia`, o Worker encerra o processamento (`200 OK`, ignorado), pois a instância que originou a emergência já está lidando com a notificação; se não possuir a label `emergencia`, envia para `#🛠️-bugs-e-feedbacks`.
- **Fila de Retentativas Assíncronas (`Cloudflare KV` + `Cron Trigger`)**:
  - Caso a criação da Issue de emergência no GitHub falhe (ex: indisponibilidade da API do GitHub), o Worker notifica o erro imediatamente no `#🚨-emergencias` do Discord e agenda uma tarefa no Cloudflare KV (`FILA_RETENTATIVAS_ALERTAS`) para tentar criar a Issue novamente no próximo ciclo do Cron Trigger (`*/5 * * * *`).
  - Caso o envio ao Discord falhe, o Worker dispara o e-mail imediato via Resend e também agenda na fila (`FILA_RETENTATIVAS_ALERTAS`) para reenviar a notificação ao Discord assim que o serviço se restabelecer.
- **Sincronização Bidirecional de Status de Issues (`Sentry <-> GitHub`)**:
  - **GitHub -> Sentry**: Ao fechar (`issues.closed`) ou reabrir (`issues.reopened`) uma Issue no GitHub cujo corpo contenha o link de uma Issue do Sentry (`sentry.io/issues/<ID>`), o Worker atualiza automaticamente o status da Issue no Sentry (`PUT /api/0/issues/<ID>/` com `status: "resolved"` ou `"unresolved"`) via `SENTRY_API_TOKEN`, ignorando ações disparadas pelo próprio bot (`aresta-climb-bot[bot]`) para evitar loops infinitos.
  - **Sentry -> GitHub**: Ao resolver ou arquivar (`sentry-hook-resource: issue` com `action: "resolved" | "archived" | "ignored"`) ou reabrir (`action: "unresolved"`) uma Issue no Sentry, o Worker localiza a Issue vinculada na organização `aresta-climb` via GitHub App (`Aresta Climb Bot`) e atualiza seu estado no GitHub (`state: "closed"` ou `"open"`).
- **Atualização da Documentação de Infraestrutura e Operação**:
  - Atualização do guia `docs/guia_configuracao_observabilidade_e_alertas.md` documentando os Webhooks do Discord, as credenciais do `Aresta Climb Bot`, o token `SENTRY_API_TOKEN` para sincronização bidirecional, a fila KV de retentativas e a manutenção da VM `e2-micro` + Docker `devlikeapro/waha:noweb` + Cloudflare Tunnel em *standby*.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; evolução direta do roteador de alertas existente. -->

### Modified Capabilities
- `roteador-alertas-whatsapp-e-fallback`: Evolução do roteador central de alertas (`cloudflare/alertas`) para suportar despacho primário via Webhooks do Discord (gist na primeira linha e `@everyone` no rodapé), criação automática de GitHub Issues de emergência via GitHub App (`Aresta Climb Bot`), deduplicação por label `emergencia`, sincronização bidirecional de status (`Sentry <-> GitHub`), fila de retentativas via Cloudflare KV + Cron Trigger, gateway WAHA em *standby* e fallback automático via Resend.

## Impact

- **`aresta_backend`**:
  - `cloudflare/alertas/src/cliente_notificacao_fake.ts` e `cloudflare/alertas/test/cliente_notificacao_fake.test.ts` (contratos e fakes determinísticos para Discord, GitHub App Issues, API do Sentry e Fila KV de retentativas).
  - `cloudflare/alertas/src/index.ts` e `cloudflare/alertas/test/index.test.ts` (implementação do `ClienteDiscordHttp`, `ClienteGithubAppHttp`, `ClienteSentryHttp`, sincronização bidirecional de status, fila KV + handler `scheduled`, filtro de label `emergencia` e coexistência com WAHA + Resend com 100% de cobertura).
  - `cloudflare/alertas/wrangler.jsonc` (configuração de `CANAL_ALERTAS_ATIVO`, binding KV `FILA_RETENTATIVAS_ALERTAS`, Cron Trigger `*/5 * * * *` e documentação das secrets do GitHub App, `SENTRY_API_TOKEN` e Discord).
- **`aresta_app` (Documentação)**:
  - `docs/guia_configuracao_observabilidade_e_alertas.md` (atualização com o fluxo unificado de Issues de emergência, sincronização bidirecional Sentry-GitHub, Discord Webhooks, fila de retentativas e `devlikeapro/waha:noweb` em standby).
