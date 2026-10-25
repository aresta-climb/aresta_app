# Design

## Context

O Worker `aresta-alertas-worker` (`aresta_backend/cloudflare/alertas/src/index.ts`) valida criptograficamente via HMAC-SHA256 os webhooks do Sentry (`/webhook/sentry`) e do GitHub (`/webhook/github`), classificando os eventos em duas categorias de severidade:
1. **Emergências (`🚨`)**: Crashes fatais, alertas de métrica/spike/uptime do Sentry e falhas de workflow do GitHub Actions na branch `main` ou tags `v*`, além de reabertura de issues de emergência.
2. **Bugs & Feedbacks (`🛠️`)**: Abertura e reabertura de GitHub Issues (sem a label `emergencia`, incluindo issues criadas pelo Sentry *First Seen* e feedbacks de usuários do app) e abertura/reabertura de Pull Requests.

Para centralizar todas as discussões técnicas no GitHub sem gerar notificações duplicadas no canal de bugs e sem perder alertas caso o GitHub ou o Discord passem por instabilidade, o próprio Worker deve criar automaticamente uma GitHub Issue com a label `emergencia` usando o GitHub App `Aresta Climb Bot` sempre que uma emergência ocorrer sem issue prévia, enviar a notificação ao Discord com o link da issue e manter uma fila de retentativas via Cloudflare KV + Cron Trigger.

## Goals / Non-Goals

**Goals:**
- Despachar alertas para dois canais de texto dedicados do Discord via Webhooks (`DISCORD_WEBHOOK_EMERGENCIAS_URL` e `DISCORD_WEBHOOK_BUGS_URL`) com o resumo direto (*gist*) na primeira linha e menção `@everyone` no rodapé da mensagem.
- Autenticar via GitHub App `Aresta Climb Bot` (`ARESTA_CLIMB_BOT_GITHUB_APP_CLIENT_ID`, `ARESTA_CLIMB_BOT_GITHUB_APP_PRIVATE_KEY`, `ARESTA_CLIMB_BOT_GITHUB_APP_INSTALLATION_ID`) e criar automaticamente uma GitHub Issue com a label `emergencia` para toda emergência oriunda do Sentry ou de falha de `workflow_run` no GitHub Actions, incluindo o link da Issue criada na notificação enviada para `#🚨-emergencias`.
- Filtrar eventos `issues` e `pull_request` nas ações `opened` e `reopened`: ignorar `issues.opened` que possuam a label `emergencia` (evitando duplicação com a instância do Worker que criou a issue de emergência) e notificar `reopened` no canal correspondente à severidade.
- Implementar fila de retentativas assíncronas (`FILA_RETENTATIVAS_ALERTAS` via Cloudflare KV + Cron Trigger `*/5 * * * *`) para reexecutar a criação de Issues ou o envio ao Discord em caso de indisponibilidade temporária.
- Manter compatibilidade total do `ClienteWahaHttp` em *standby* controlado por `CANAL_ALERTAS_ATIVO` (`"discord" | "whatsapp" | "ambos"`).
- Preservar o fallback automático imediato por e-mail via **Resend (`contato@arestaclimb.com`)** sempre que o canal primário configurado falhar.
- Manter 100% de cobertura comportamental de testes unitários com Fakes determinísticos (`ClienteDiscordFake`, `ClienteGithubAppFake`, `FilaRetentativasFake`, `ClienteWahaFake`, `ClienteResendFake`) sem uso de mocks.

**Non-Goals:**
- Remover ou desprovisionar a VM `e2-micro`, o container `waha:noweb` ou o túnel `waha-gcp` (eles permanecem provisionados em *standby*).
- Utilizar tokens pessoais de desenvolvedor (PAT) para o GitHub (utilizaremos exclusivamente o GitHub App oficial `Aresta Climb Bot`).

## Decisions

### 1. Posicionamento de `@everyone` no Rodapé e Gist na Primeira Linha
- **Decisão**: O `ClienteDiscordHttp` posicionará `\n\n@everyone` ao final de `opcoes.texto` (caso ainda não contenha `@everyone`) e enviará `allowed_mentions: { parse: ["everyone"] }`. A primeira linha de cada alerta trará o resumo compacto do evento (`🚨 [EMERGÊNCIA] ...` ou `🛠️ [ISSUE #N] ...`).
- **Racional**: Os sistemas operacionais móveis (iOS/Android) e smartwatches exibem apenas os primeiros 50–80 caracteres na prévia da notificação push. Colocar o *gist* na primeira linha garante leitura imediata do problema na tela de bloqueio, enquanto o `@everyone` no rodapé continua acionando normalmente o som de push e o badge vermelho no Discord.

### 2. Criação Automática de Issue de Emergência via GitHub App (`Aresta Climb Bot`) e Deduplicação
- **Decisão**:
  - Implementar `ClienteGithubAppHttp` (`InterfaceClienteGithubApp`) que assina um JWT RS256 usando `crypto.subtle` nativo do Cloudflare Workers com `ARESTA_CLIMB_BOT_GITHUB_APP_PRIVATE_KEY` e `ARESTA_CLIMB_BOT_GITHUB_APP_CLIENT_ID`, obtém o *installation token* (`POST /app/installations/{id}/access_tokens`) e cria a Issue (`POST /repos/{owner}/{repo}/issues`) com `labels: ["emergencia"]`.
  - Mapeamento de repositório para emergências do Sentry: derivado da tag `service` ou nome do projeto (`aresta-app` -> `aresta-climb/aresta_app`, `aresta-backend` -> `aresta-climb/aresta_backend`, `arestaclimb-com` -> `aresta-climb/arestaclimb.com`, fallback `aresta-climb/aresta_app`). Para `workflow_run` do GitHub, utiliza `payload.repository.full_name`.
  - Quando `issues.opened` chegar ao `/webhook/github` contendo a label `emergencia`, o Worker retorna `200 OK` (`ignorado: true`) imediatamente, pois a instância que originou a emergência já está enviando a notificação para `#🚨-emergencias` com o link da Issue criada.
  - Eventos `issues.reopened` e `pull_request.reopened` são processados e enviados ao canal correspondente (`#🚨-emergencias` se tiver label `emergencia`, ou `#🛠️-bugs-e-feedbacks` caso contrário).

### 3. Fila de Retentativas com Cloudflare KV e Cron Trigger (`scheduled`)
- **Decisão**:
  - Se a criação da Issue no GitHub falhar (outage do GitHub): o Worker envia imediatamente o alerta para `#🚨-emergencias` no Discord avisando que o GitHub falhou ao criar a issue e grava um item do tipo `criar_issue_emergencia` no KV (`FILA_RETENTATIVAS_ALERTAS`).
  - Se o envio ao Discord falhar (outage do Discord): o Worker dispara imediatamente o e-mail de contingência via Resend e grava um item do tipo `enviar_notificacao_discord` no KV (`FILA_RETENTATIVAS_ALERTAS`).
  - O handler `scheduled` do Worker (executado a cada 5 minutos via Cron Trigger `"*/5 * * * *"`) varre as chaves pendentes no KV, reexecuta a operação e remove a chave em caso de sucesso (ou descarta após atingir o limite máximo de tentativas / TTL de 24h).
- **Racional**: Cloudflare KV e Cron Triggers fazem parte do plano 100% gratuito do Cloudflare Workers ($0,00/mês), garantindo entrega eventual sem custos de Cloudflare Queues.

### 4. Sincronização Bidirecional de Status de Issues (`Sentry <-> GitHub`)
- **Decisão**:
  - **GitHub -> Sentry**: Ao processar `issues.closed` ou `issues.reopened` disparados por usuários não-bot (`sender.type !== "Bot"`), o Worker extrai o ID numérico da Issue do Sentry presente no corpo da GitHub Issue (`sentry.io/issues/([0-9]+)`) e invoca `ClienteSentryHttp.atualizarStatusIssue(idSentry, status)` (`PUT https://sentry.io/api/0/issues/{id}/` com `{ status: "resolved" | "unresolved" }`) autenticando com `SENTRY_API_TOKEN`.
  - **Sentry -> GitHub**: Ao receber `sentry-hook-resource: issue` com `action` em `["resolved", "archived", "ignored", "unresolved"]`, o Worker extrai `payload.data.issue.id` e invoca `ClienteGithubAppHttp.sincronizarEstadoIssuePorIdSentry(idSentry, novoEstado)` que consulta `GET /search/issues?q=org:aresta-climb+is:issue+"sentry.io/issues/{id}"` e atualiza o `state` (`"closed"` ou `"open"`) das issues correspondentes via `PATCH /repos/{owner}/{repo}/issues/{number}`.
  - **Prevenção de Loop**: A verificação `sender.type === "Bot" || sender.login?.includes("aresta-climb-bot")` no evento do GitHub impede que o fechamento/reabertura efetuado pelo próprio bot dispare uma chamada reversa redundante ao Sentry.

## Risks / Trade-offs

- **[Formato PKCS#1 vs PKCS#8 da Private Key do GitHub App no Web Crypto]** → O GitHub gera chaves privadas RSA em formato PEM PKCS#1 (`-----BEGIN RSA PRIVATE KEY-----`), enquanto `crypto.subtle.importKey("pkcs8", ...)` exige PKCS#8. O cliente converterá automaticamente chaves PKCS#1 para o envelope ASN.1 PKCS#8 em memória antes de importar no `crypto.subtle`, suportando ambos os formatos de forma transparente.
- **[Limite de 2000 caracteres do Discord]** → O `ClienteDiscordHttp` truncará o corpo da mensagem antes do sufixo `\n\n@everyone` caso o texto ultrapasse 1990 caracteres, garantindo que a menção `@everyone` no rodapé nunca seja cortada pelo truncamento.

## Migration Plan

1. Expandir contratos e fakes determinísticos em `cliente_notificacao_fake.ts` (`InterfaceClienteGithubApp`, `ClienteGithubAppFake`, `InterfaceFilaRetentativas`, `FilaRetentativasFake`) com TDD.
2. Implementar `ClienteGithubAppHttp`, fila KV + `scheduled`, posicionamento de `@everyone` no rodapé e filtro de `opened`/`reopened` com label `emergencia` em `src/index.ts` com 100% de cobertura.
3. Configurar o namespace KV `FILA_RETENTATIVAS_ALERTAS`, o Cron Trigger em `wrangler.jsonc` e as secrets do `Aresta Climb Bot` no Worker, realizando o deploy e validação.
