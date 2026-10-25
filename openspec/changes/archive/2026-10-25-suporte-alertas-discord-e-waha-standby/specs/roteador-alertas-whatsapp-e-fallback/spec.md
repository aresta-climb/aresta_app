# Spec Delta: roteador-alertas-whatsapp-e-fallback

## ADDED Requirements

### Requirement: Despacho via Webhooks do Discord com Gist na Primeira Linha e Menção no Rodapé
Quando as URLs de Webhook do Discord (`DISCORD_WEBHOOK_EMERGENCIAS_URL` para emergências ou `DISCORD_WEBHOOK_BUGS_URL` para bugs/feedbacks/PRs) estiverem configuradas no ambiente do Worker e o canal Discord estiver ativo (`CANAL_ALERTAS_ATIVO` igual a `"discord"` ou `"ambos"`), o sistema SHALL enviar a notificação ao respectivo Webhook do Discord iniciando com o resumo direto do problema (*gist*) na primeira linha e posicionando a menção `@everyone` no rodapé (final da mensagem) com `allowed_mentions: { parse: ["everyone"] }` para exibir o resumo na prévia da notificação móvel e acionar push sonoro e badge numérico.

#### Scenario: Envio de alerta de emergência via Webhook do Discord com gist no topo e @everyone no rodapé
- **WHEN** um alerta classificado como emergência for processado e `DISCORD_WEBHOOK_EMERGENCIAS_URL` estiver configurada no ambiente
- **THEN** o sistema DEVE realizar um `POST` para `DISCORD_WEBHOOK_EMERGENCIAS_URL` contendo o resumo (*gist*) na primeira linha, o link da GitHub Issue de emergência criada (quando disponível) e `@everyone` no final da mensagem, retornando status HTTP `200` com `entregueVia: "discord"`.

#### Scenario: Envio de nova issue ou PR via Webhook do Discord de Bugs e Feedbacks
- **WHEN** uma abertura ou reabertura de issue (sem a label `emergencia`) ou Pull Request for processada e `DISCORD_WEBHOOK_BUGS_URL` estiver configurada no ambiente
- **THEN** o sistema DEVE realizar um `POST` para `DISCORD_WEBHOOK_BUGS_URL` contendo o resumo (*gist*) na primeira linha, os links da issue/PR e `@everyone` no final da mensagem, retornando status HTTP `200` com `entregueVia: "discord"`.

#### Scenario: Coexistência em standby com o gateway WAHA do WhatsApp
- **WHEN** o ambiente estiver configurado com `CANAL_ALERTAS_ATIVO: "discord"` (ou sem credenciais do WAHA)
- **THEN** o sistema DEVE entregar o alerta diretamente ao Discord sem falhar por ausência ou inatividade do WAHA, mantendo o código e o suporte ao WAHA prontos para ativação imediata via variáveis de ambiente.

### Requirement: Criação Automática de GitHub Issues de Emergência via GitHub App e Deduplicação por Label
Quando o Worker receber um evento de emergência que ainda não possua uma GitHub Issue associada (Crash Fatal, Spike de `metric_alert` ou Queda de Uptime no Sentry, ou falha de `workflow_run` no GitHub Actions na branch `main` ou tags `v*`), o sistema SHALL autenticar utilizando o GitHub App `Aresta Climb Bot` (`ARESTA_CLIMB_BOT_GITHUB_APP_CLIENT_ID`, `ARESTA_CLIMB_BOT_GITHUB_APP_PRIVATE_KEY`, `ARESTA_CLIMB_BOT_GITHUB_APP_INSTALLATION_ID`), criar automaticamente uma nova Issue com a label `emergencia` no repositório correspondente da organização `aresta-climb` e incluir o link da Issue recém-criada na notificação enviada ao canal `#🚨-emergencias`. Adicionalmente, ao receber eventos `issues` do GitHub, o sistema SHALL filtrar pela label `emergencia` para impedir duplicações no canal de bugs.

#### Scenario: Emergência do Sentry ou falha de GitHub Actions cria Issue com label emergencia e notifica com link
- **WHEN** o Worker receber um webhook válido de emergência do Sentry (`metric_alert` ou `event_alert` fatal) ou falha de `workflow_run` em `main`/`v*` e as credenciais do GitHub App estiverem configuradas
- **THEN** o sistema DEVE criar uma Issue no repositório correspondente com a label `emergencia` via API do GitHub e enviar a notificação ao canal `#🚨-emergencias` contendo o `html_url` da Issue criada.

#### Scenario: Abertura de Issue com label emergencia é ignorada para evitar duplicação
- **WHEN** o Worker receber um webhook do GitHub `issues` com `action: "opened"` cuja issue possua a label `emergencia`
- **THEN** o sistema DEVE encerrar o processamento imediatamente retornando status HTTP `200` (`ignorado: true`), sem enviar notificação duplicada ao canal `#🛠️-bugs-e-feedbacks` nem ao `#🚨-emergencias`.

#### Scenario: Reabertura de Issue é notificada no canal correspondente à sua severidade
- **WHEN** o Worker receber um webhook do GitHub `issues` com `action: "reopened"` (ou `pull_request` com `action: "reopened"`)
- **THEN** o sistema DEVE enviar a notificação de reabertura para `#🛠️-bugs-e-feedbacks` caso não possua a label `emergencia`, ou para `#🚨-emergencias` caso possua a label `emergencia`.

### Requirement: Fila de Retentativas Assíncronas para Falhas do GitHub e do Discord
Quando a criação automática da Issue de emergência no GitHub falhar (ex: outage ou erro `5xx`/`429` na API do GitHub) ou quando o envio da notificação ao Discord falhar, o sistema SHALL registrar a operação pendente na fila persistente (`FILA_RETENTATIVAS_ALERTAS` via Cloudflare KV) para reprocessamento automático no próximo ciclo agendado (`scheduled` Cron Trigger).

#### Scenario: Falha ao criar Issue de emergência no GitHub notifica imediatamente no Discord e agenda retentativa
- **WHEN** o Worker tentar criar uma Issue de emergência via GitHub App e a API do GitHub retornar erro ou timeout
- **THEN** o sistema DEVE enviar imediatamente o alerta de emergência para `#🚨-emergencias` no Discord informando a indisponibilidade temporária do GitHub e enfileirar a criação da Issue em `FILA_RETENTATIVAS_ALERTAS` para nova tentativa no próximo ciclo do Cron Trigger.

#### Scenario: Reprocessamento agendado conclui criação de Issue ou entrega pendente ao Discord
- **WHEN** o Cron Trigger (`scheduled`) do Worker for executado e houver itens pendentes em `FILA_RETENTATIVAS_ALERTAS`
- **THEN** o sistema DEVE reexecutar a criação da Issue no GitHub (enviando o link resultante ao `#🚨-emergencias`) e/ou reenviar a notificação pendente ao Discord, removendo o item da fila em caso de sucesso.

### Requirement: Sincronização Bidirecional de Status de Issues entre Sentry e GitHub
O sistema SHALL sincronizar bidirecionalmente o estado de resolução/fechamento e reabertura de issues entre o Sentry e o GitHub utilizando `SENTRY_API_TOKEN` e o GitHub App `Aresta Climb Bot`, prevenindo loops infinitos quando a própria automação realizar a alteração de status.

#### Scenario: Fechamento ou reabertura de Issue no GitHub atualiza o status correspondente no Sentry
- **WHEN** o Worker receber um webhook do GitHub `issues` com `action: "closed"` ou `action: "reopened"` originado por um usuário humano (`sender.type !== "Bot"`), cujo corpo da issue contenha um link de Issue do Sentry (`sentry.io/issues/<ID>`)
- **THEN** o sistema DEVE enviar uma requisição `PUT https://sentry.io/api/0/issues/<ID>/` com `status: "resolved"` (quando fechada) ou `status: "unresolved"` (quando reaberta).

#### Scenario: Resolução, arquivamento ou reabertura de Issue no Sentry atualiza a Issue vinculada no GitHub
- **WHEN** o Worker receber um webhook do Sentry com `sentry-hook-resource: issue` e `action` igual a `"resolved"`, `"archived"`, `"ignored"` ou `"unresolved"`
- **THEN** o sistema DEVE buscar a Issue correspondente na organização `aresta-climb` via GitHub App e atualizar seu estado para `"closed"` (quando resolvida/arquivada/ignorada) ou `"open"` (quando marcada como `"unresolved"`).

#### Scenario: Prevenção de loop infinito quando o próprio bot altera o estado no GitHub
- **WHEN** o Worker receber um webhook do GitHub `issues` (`closed` ou `reopened`) cujo `sender.type === "Bot"` ou `sender.login` pertença ao `aresta-climb-bot`
- **THEN** o sistema NÃO DEVE invocar a API do Sentry para atualizar o status novamente.

## MODIFIED Requirements

### Requirement: Fallback Automático por E-mail via Resend sem Loop de Erro
Quando o envio da notificação para o canal primário configurado (Webhook do Discord e/ou gateway WAHA do WhatsApp) falhar por erro de rede, timeout, ausência de canal primário configurado ou status HTTP diferente de `2xx`, o sistema SHALL disparar automaticamente o conteúdo do alerta por e-mail utilizando a API do Resend (`POST https://api.resend.com/emails`) para `contato@arestaclimb.com` (com remetente `alerta@login.arestaclimb.com`), enfileirar a entrega para nova tentativa no Discord (quando aplicável) e abster-se de registrar exceção recursiva no Sentry caso o próprio alerta seja oriundo de falha.

#### Scenario: Indisponibilidade da VM do WAHA aciona envio via Resend
- **WHEN** o Worker `cloudflare/alertas` tentar enviar uma mensagem ao endpoint REST do WAHA e receber erro HTTP `502`/`503` ou timeout
- **THEN** o sistema DEVE enviar um e-mail via API do Resend para `contato@arestaclimb.com` contendo o alerta original na íntegra acrescido de um banner avisando o motivo da falha no gateway do WhatsApp.

#### Scenario: Sucesso no envio ao WhatsApp não aciona o Resend
- **WHEN** o gateway WAHA responder com status HTTP `200` ou `201` ao envio da mensagem de alerta
- **THEN** o sistema NÃO DEVE invocar a API do Resend.

#### Scenario: Indisponibilidade do Webhook do Discord aciona envio via Resend e agenda retentativa na fila
- **WHEN** o Worker `cloudflare/alertas` tentar enviar uma mensagem ao Webhook do Discord e receber erro HTTP (`500`/`502`/`503`/`429`) ou falha de conexão
- **THEN** o sistema DEVE enviar um e-mail via API do Resend para `contato@arestaclimb.com` contendo o alerta original na íntegra acrescido de um banner avisando o motivo da falha no Discord e registrar a mensagem na fila `FILA_RETENTATIVAS_ALERTAS` para reenvio posterior ao Discord.

#### Scenario: Sucesso no envio ao Discord não aciona o Resend
- **WHEN** o Webhook do Discord responder com status HTTP `2xx` (`200` ou `204`) ao envio da mensagem de alerta
- **THEN** o sistema NÃO DEVE invocar a API do Resend.

### Requirement: Documentação Passo a Passo de Provisionamento e Configuração
O repositório SHALL conter um guia técnico detalhado em português brasileiro (`docs/guia_configuracao_observabilidade_e_alertas.md`) documentando passo a passo a configuração do Sentry Open Source, da integração com GitHub Issues e GitHub App (`Aresta Climb Bot`), da criação dos 2 Webhooks do Discord (`#🚨-emergencias` e `#🛠️-bugs-e-feedbacks`), da fila KV de retentativas, da manutenção em *standby* da VM gratuita `e2-micro` no Google Cloud Platform com Docker (`devlikeapro/waha:noweb`) e Cloudflare Tunnel, do Webhook Organizacional do GitHub e dos segredos do Resend e Cloudflare.

#### Scenario: Consulta ao guia de configuração completa da infraestrutura
- **WHEN** um desenvolvedor consultar `docs/guia_configuracao_observabilidade_e_alertas.md` para provisionar ou auditar o ambiente de produção
- **THEN** o documento DEVE apresentar comandos reproduzíveis e instruções completas para Webhooks do Discord, credenciais do GitHub App `Aresta Climb Bot`, fila KV `FILA_RETENTATIVAS_ALERTAS`, GCP `e2-micro`, Docker Compose do WAHA (`devlikeapro/waha:noweb`) + `cloudflared` em standby, obtenção de IDs de grupos do WhatsApp, configuração de projetos e alertas no Sentry, webhook organizacional no GitHub e variáveis de ambiente do Cloudflare/Supabase.
